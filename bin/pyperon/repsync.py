#!/usr/bin/env python

import configparser
import logging
import os
from collections import OrderedDict
from pathlib import Path
import re

import click
import requests

__version__ = '0.1.2'

from pyperon import cmd

APP_NAME = 'repo'
HOME = os.getenv('HOME', '/home/' + os.getenv('USER'))
RESERVED = ('DEFAULT', 'SETTINGS')

# You only need to set the logger config once really
logging.basicConfig(
    level=logging.ERROR,
    format='[%(levelname)s]: %(message)s',
    datefmt="%Y-%m-%d %H:%M:%S")

LOG = logging.getLogger('pyperon.repsync')


def first(func, it):
    return next(filter(func, it), None)


class ServiceNotFound(Exception):
    pass


class Manager:
    _registry = {}

    def __init__(self, config=None, basedir=None, verbose=0, quiet=False):
        self.services = OrderedDict()
        self.cfg = None
        self.config_path = None
        self.basedir = basedir
        self.verbose = min(verbose, 4)
        self.quiet = quiet
        self._configure_log()
        self.load(config)

    def load(self, config=None):
        if config is not None:
            self.config_path = Path(config)
        if self.config_path and not self.cfg:
            self._load_config()
        if self.cfg:
            self._load_services()

    def get_basedir(self):
        basedir = Path(self.basedir) if self.basedir else Path.cwd()
        if not basedir.exists():
            # try to create basedir
            try:
                basedir.mkdir(parents=True)
            except (FileNotFoundError, OSError) as e:
                LOG.exception(f'Invalid base directory: {basedir}')
                exit(4)
        return basedir

    def _configure_log(self):
        verbosity = 50 - (10 * self.verbose) if self.verbose > 0 else 0
        if verbosity <= 0:
            verbosity = logging.ERROR
        LOG.setLevel(verbosity)
        LOG.debug("Setting LogLevel to [%i]: %s", verbosity, logging.getLevelName(verbosity))
        if self.verbose >= 3:
            logging.getLogger().setLevel(logging.DEBUG)
            requests_log = logging.getLogger("urllib3")
            requests_log.setLevel(logging.DEBUG)
            requests_log.propagate = True

    def _load_services(self):
        # process configuration
        LOG.debug("Loading services ..")
        services = [sect for sect in self.cfg.sections() if sect.upper() not in RESERVED]
        for name in services:
            self.services[name] = self._load_service(name)

    def _load_service(self, name):
        srv_cfg = dict(self.cfg[name])
        if not srv_cfg.get('name', None):
            srv_cfg['name'] = name
        srv_cls_name = srv_cfg.get('class', srv_cfg.get('server', None))
        srv_cls = Manager.get_server_class(srv_cls_name)
        LOG.debug("Loading service [%s]: %s", name, srv_cls_name)
        if srv_cls is not None:
            inst = srv_cls(**srv_cfg)
            #inst.name = name
        return inst

    def _load_config(self):
        LOG.debug("Loading config: %s ", self.config_path)
        self.cfg = configparser.ConfigParser()
        self._create_config()
        self.cfg.read(self.config_path)

    def _create_config(self):
        # SETTING DEFAULTS
        self.cfg['SETTINGS'] = {
            'types': 'GitHub,Bitbucket,GitLab',
            'main': ''
        }
        self.cfg['DEFAULT'] = {
            "id": "user@host",
            "class": "GitHub|Bitbucket|GitLab",
            "user": "user",
            "token": "xxxxx"
        }
        LOG.debug("Creating config file: %s ", self.config_path)
        if not self.config_path.exists():
            with self.config_path.open('w') as wr:
                self.cfg.write(wr)

    @staticmethod
    def register(cls):
        Manager._registry[cls.__name__.lower()] = cls
        return cls

    @staticmethod
    def get_server_class(name):
        if name.lower() in Manager._registry:
            return Manager._registry[name.lower()]
        else:
            return None

    def run_services(self, project, func, names=None, **kwargs):
        # check if names is a string, and split-it
        assert callable(func)
        if names is not None:
            if isinstance(names, str):
                names = names.replace(',', ' ').replace('|', ' ').replace(':', ' ') \
                    .replace(';', ' ').split(' ')
            if not isinstance(names, (list, tuple,)):
                raise ValueError('names passed to Manager.run_services must be string or list')
        result = {}
        for nm, svc in self.services.items():
            if names is not None:
                if nm not in names:
                    LOG.debug(f'Ignoring service name {nm}')
                    continue
            else:
                result[nm] = func(svc, project, **kwargs)
        return result

    def _from_names(self, names):
        if names is not None:
            if isinstance(names, str):
                names = names.replace(',', ' ').replace('|', ' ').replace(':', ' ') \
                    .replace(';', ' ').split(' ')
            if not isinstance(names, (list, tuple,)):
                raise ValueError('names passed must be string or list')
        return names


    def get_services_by_names(self, names, error=False):
        norm_names = self._from_names(names)
        if 'all' in norm_names:
            return self.services.values()
        else:
            svcs = [v for k,v in self.services.items() if k in names]
            if error and len(norm_names) != len(svcs):
                raise ValueError("Invalid service name provided!")
            return svcs

    def get_service(self, name):
        if not name:
            return None
        return self.services.get(name, None)

    def find_service(self, repo):
        """
            Iterate over all servers and stop on fist found repo
            for cloning and other settings
        """
        # first try main defined in conf
        def _find(svc):
            return svc.exist_repo(repo) if svc else False

        services = [self.get_main()]
        services.extend(self.services.values())

        for svc in services:
            if _find(svc):
               return svc
        return None


    def get_main(self):
        return self.get_service(self.cfg['SETTINGS'].get('main', ''))



class Server:
    NAME = 'Server'
    SITE = "github.com"
    API_SITE = "https://localhost/"
    API_LIST = ""
    API_CREATE = ""
    API_DELETE = ""
    API_GET = ""

    def __init__(self, user=None, token=None, **kwargs):
        self.cfg = {}
        self.repos = {}
        self.user = user
        self.token = token
        self.clazz = self.__class__
        self.name = kwargs.pop('name', '')
        self.id = kwargs.pop('id', self.user + '@' + self.clazz.__name__.lower())
        self.description = kwargs.pop('description', '')
        self.cfg.update(kwargs)

    def _upd_headers(self, headers):
        if 'Content-Type' not in headers:
            headers['Content-Type'] = 'application/json'

    def _fmt_addr(self, addr, **kwargs):
        fmt = {**self.__dict__}
        fmt.update(kwargs)
        final_addr = addr
        if '://' not in addr:
            final_addr = (self.API_SITE[:-1] if self.API_SITE[-1] == '/' else self.API_SITE)
            final_addr = final_addr + "/" + (addr[1:] if addr[0] == '/' else addr)
        return final_addr.format(**fmt)

    def _request(self, addr, method=requests.get, **kwargs):
        headers = kwargs.pop('headers', {})
        self._upd_headers(headers)
        final_addr = self._fmt_addr(addr)
        return method(final_addr, headers=headers, **kwargs)

    def _do_get(self, addr, **kwargs):
        return self._request(addr, method=requests.get, **kwargs)

    def _do_post(self, addr, **kwargs):
        return self._request(addr, method=requests.post, **kwargs)

    def _do_delete(self, addr, **kwargs):
        return self._request(addr, method=requests.delete, **kwargs)

    def _parse(self, rv):
        result = []
        for repo in rv:
            self.repos[repo['name']] = repo
            result.append(repo['name'])
        return result

    def list_repos(self):
        r = self._do_get(self.API_LIST)
        rv = r.json()
        return self._parse(rv)

    def create_repo(self, repo_name, **kwargs):
        raise NotImplementedError("function must be implemented!")

    def delete_repo(self, repo_name, **kwargs):
        raise NotImplementedError("function must be implemented!")

    def get_repo(self, repo_name, **kwargs):
        workspace = self.cfg.get('workspace') or self.user
        if repo_name in self.repos:
            return self.repos[repo_name]
        else:
            addr = self._fmt_addr(self.API_GET, workspace=workspace, user=self.user, repo_name=repo_name)
            r = self._do_get(addr, **kwargs)
            if r.status_code == 200:
                rv = r.json()
                self.repos[repo_name] = rv
                return rv
            else:
                return {}

    def exist_repo(self, repo_name, **kwargs):
        if repo_name in self.repos:
            repo = self.repos[repo_name]
        else:
            repo = self.get_repo(repo_name, **kwargs)
        return bool(repo)

    def get_git_url(self, repo_name):
        return f'git@{self.SITE}:{self.user}/{repo_name}.git'


@Manager.register
class GitHub(Server):
    NAME = 'GitHub'
    SITE = "github.com"
    API_SITE = "https://api.github.com/"
    API_LIST = "user/repos?type=all&per_page=1000"
    API_CREATE = "user/repos"
    API_DELETE = "repos/{user}/{repo_name}"
    API_GET = "repos/{user}/{repo_name}"

    def _upd_headers(self, headers):
        super()._upd_headers(headers)
        if 'Authorization' not in headers:
            if self.token:
                headers['Authorization'] = "token " + self.token

    def create_repo(self, repo_name, **kwargs):
        payload = {
            "name": repo_name,
            "description": kwargs.get('description', ''),
            "homepage": kwargs.get('homepage', ''),
            "private": "true",
            "has_issues": "true",
            "has_projects": "true",
            "has_wiki": "true"
        }
        r = self._do_post(addr=self.API_CREATE, json=payload)
        if r.status_code in (200, 201,):
            self.repos[repo_name] = r.json()
        return r.status_code in (400, 200, 201)

    def delete_repo(self, repo_name, **kwargs):
        api_addr = self._fmt_addr(self.API_DELETE, user=self.user, repo_name=repo_name)
        r = self._do_delete(api_addr)
        return r.status_code == 204


@Manager.register
class BitBucket(Server):
    NAME = 'Bitbucket'
    SITE = "bitbucket.org"
    API_SITE = "https://api.bitbucket.org/"
    API_LIST = "2.0/repositories/{user}?pagelen=100"
    API_CREATE = "2.0/repositories/{workspace}/{repo_name}"
    API_DELETE = "2.0/repositories/{workspace}/{repo_name}"
    API_GET = "2.0/repositories/{workspace}/{repo_name}"

    def _request(self, addr, method=requests.get, **kwargs):
        auth = kwargs.pop('auth', None)
        if auth is None:
            auth = (self.user, self.token)
        return super()._request(addr, method=method, auth=auth, **kwargs)

    def _parse(self, rv):
        result = []
        for repo in rv.get('values', []):
            self.repos[repo['name']] = repo
            result.append(repo['name'])
        return result

    def create_repo(self, repo_name, **kwargs):
        workspace = self.cfg.get('workspace') or self.user
        project = self.cfg.get('project') or 'DEV'
        api_addr = self._fmt_addr(self.API_CREATE, workspace=workspace, user=self.user, repo_name=repo_name)
        body = {
            "scm": "git",
            "is_private": "true",
            "fork_policy": "no_public_forks",
            "project": {
                "key": project
            }
        }
        r = self._do_post(api_addr, json=body)
        if r.status_code in (200, 201,):
            self.repos[repo_name] = r.json()
        return r.status_code in (400, 200, 201)

    def delete_repo(self, repo_name, **kwargs):
        workspace = self.cfg.get('workspace') or self.user
        api_addr = self._fmt_addr(self.API_DELETE, workspace=workspace, user=self.user, repo_name=repo_name)
        r = self._do_delete(api_addr)
        return r.status_code == 204


@Manager.register
class GitLab(Server):
    NAME = 'GitLab'
    SITE = "gitlab.com"
    API_SITE = "https://gitlab.com/api/"
    API_LIST = "v4/projects?owned=true&per_page=1000&page=1"
    API_CREATE = "v4/projects"
    API_DELETE = "v4/projects/{user}%2F{repo_name}"
    API_GET = "v4/projects?owned=true&search={repo_name}"

    def _upd_headers(self, headers):
        super()._upd_headers(headers)
        if 'Authorization' not in headers:
            if self.token:
                headers['Authorization'] = "token " + self.token
                headers['Private-Token'] = self.token

    def list_repos(self):
        r = self._do_get(self.API_LIST)
        rv = r.json()
        return [repo['name'] for repo in rv]

    def create_repo(self, repo_name, **kwargs):
        api_addr = self._fmt_addr(self.API_CREATE, user=self.user, repo_name=repo_name)
        body = {
            "name": repo_name,
            "description": kwargs.get('description', ''),
            "visibility": "private"
        }
        r = self._do_post(api_addr, json=body)
        if r.status_code in (200, 201,):
            self.repos[repo_name] = r.json()
        return r.status_code in (400, 200, 201,)

    def delete_repo(self, repo_name, **kwargs):
        api_addr = self._fmt_addr(self.API_DELETE, user=self.user, repo_name=repo_name)
        r = self._do_delete(api_addr)
        return r.status_code == 204

    def get_repo(self, repo_name, **kwargs):
        if repo_name in self.repos:
            return self.repos[repo_name]
        else:
            addr = self._fmt_addr(self.API_GET, user=self.user, repo_name=repo_name)
            r = self._do_get(addr, **kwargs)
            if r.status_code == 200:
                rv = r.json()
                repo = [pj for pj in rv if pj['name'] == repo_name]
                if repo:
                    self.repos[repo_name] = repo[0]
                    return repo[0]
                else:
                    return {}
            else:
                return {}


def _dummy_echo(*args, **kwargs):
    pass


def exit_with_msg(message, show_help=False):
    ctx = click.get_current_context()
    if show_help:
        click.echo(ctx.get_help())
    ctx.fail(message)


def _show_help(ctx, param, value):
    click.echo(ctx.get_help())
    ctx.exit()


@click.group(invoke_without_command=True)
@click.option(
    '-c', '--config', 'cfg', type=click.Path(writable=True, file_okay=True, dir_okay=False),
    default=f"{HOME}/.config/{APP_NAME}.conf",
    help='Defines the config file to load repository servers',
)
@click.option(
    '--basedir', '-d', type=click.Path(exists=True, file_okay=False, dir_okay=True),
    default=None,
    help='Define the base dir from system will put projects'
)
@click.option('-v', '--verbose', count=True, help='Sets verbosity of output')
@click.option('--quiet/', '-q/', is_flag=True, help='No output at all')
@click.help_option('-h', '--help')
@click.pass_context
def cli(ctx, cfg, basedir, verbose, quiet):
    if verbose > 0 and quiet:
        exit_with_msg('Incompatible options!! Cannot pass -v|--verbose and -q|--quiet')

    if quiet:  # disable output on quietly
        click.echo = _dummy_echo
        click.secho = _dummy_echo
        verbose = 0

    LOG.debug(f"Config   : {cfg}")
    LOG.debug(f"Basedir  : {basedir}")
    LOG.debug(f"Verbosity: {verbose}")

    # create ctx.obj instance
    mgr = Manager(config=cfg, basedir=basedir, verbose=verbose, quiet=quiet)
    ctx.obj = mgr
    # calls default action if not set
    if ctx.invoked_subcommand is None:
        exit_with_msg('No subcommand given!', show_help=True)
        return 4

@cli.command()
@click.option('-f', '--force', is_flag=True, default=False)
@click.pass_obj
def config(mgr, force):
    settings = {
        'user.name': 'Marcos Peron',
        'user.email': 'mperon@outlook.com',
        'core.editor': 'vim',
        'merge.tool': 'vimdiff',
        'color.status': 'auto',
        'color.branch': 'auto',
        'color.interactive': 'auto',
        'color.diff': 'auto'
    }
    click.echo('Configuring default settings..')
    current = cmd.output('git config --global --list')
    for nm, value in settings.items():
        if force:
            LOG.debug(f"Setting config {nm}: {value}")
            cmd.run(['git', 'config', '--global', nm, value])
        else:
            exists = current.filter_by(f'alias.{nm}=')
            if exists.is_empty():
                LOG.debug(f"Setting config {nm}: {value}")
                cmd.run(['git', 'config', '--global', nm, value])


def _ensure_repos_exists(mgr, project):
    # create all remotes first
    LOG.debug(f"Ensure that remotes services exists...")
    for service in mgr.services.values():
        # cria projetos remotos
        if not service.exist_repo(project):
            LOG.debug(f"Service {service.name} doesnt exists:")
            # tries to create it
            if not service.create_repo(project):
                exit_with_msg(f"Was impossible to create {project} on {service.SITE}")
            LOG.debug(f"Created!")
        else:
            LOG.debug(f"Service {service.name} already exists.")


def _ensure_remotes(mgr, project, add_remotes, cwd=None):
    cwd = cwd if cwd else mgr.get_basedir()
    project_dir = Path(cwd) / project
    # Processa todos os remotes
    click.echo(f"Getting remotes of project {project}")

    main_svc = mgr.get_main()
    if main_svc:
        remotes = cmd.output('git remote --verbose', cwd=project_dir)
        origin = remotes.filter_by('origin')
        if origin.is_empty():
            cmd.run(['git', 'remote', 'add', 'origin', main_svc.get_git_url(project)], cwd=project_dir)

    # check each server twice
    for time in range(2):
        remotes = cmd.output('git remote --verbose', cwd=project_dir)
        for service in mgr.services.values():
            # get git url
            git_url = service.get_git_url(project)

            if add_remotes:
                rem_svc = remotes.filter_by(service.name + "\t", git_url)
                if rem_svc.is_empty():
                    cmd.run(['git', 'remote', 'add', service.name, git_url], cwd=project_dir)

            # check for origin
            rem_svc = remotes.filter_by('origin', git_url, '(push)')
            if rem_svc.is_empty():
                cmd.run(['git', 'remote', 'set-url', '--add', '--push', 'origin', git_url],
                    cwd=project_dir)

    #verify main is fetch
    if main_svc:
        remotes = cmd.output('git remote --verbose', cwd=project_dir)
        fetch = remotes.filter_by('origin', main_svc.get_git_url(project), '(fetch)')
        if fetch.is_empty():
            #main isnt fetch
            click.echo("Main service: {} isnt used for fetch. Fixing.".format(main_svc.name))
            cmd.run(['git', 'remote', 'set-url', '--delete', 'origin'], cwd=project_dir)
            cmd.run(['git', 'remote', 'set-url', 'origin', main_svc.get_git_url(project)], cwd=project_dir)


@cli.command()
@click.argument('projects', nargs=-1)
@click.option('-a', '--add-remotes', 'add_remotes', is_flag=True, default=False)
@click.pass_obj
def install(mgr, projects, add_remotes):
    LOG.debug("Calling install!!")
    cwd = mgr.get_basedir()
    LOG.debug(f"Current Directory: {cwd}")
    for project in projects:
        clone_svc = None
        # check project exists
        LOG.debug(f"Processing project: {project}")
        project_dir = Path(cwd) / project
        LOG.debug(f"Project dir: {project_dir}")

        if project_dir.is_dir():
            #verifica se a pasta existe
            is_git = cmd.output("git rev-parse --git-dir", cwd=project_dir)
            if is_git.is_error():
                LOG.debug(f"Path {project_dir} is not a git dir. Initializing..")
                #is not a git dir, initialize
                cmd.run("git init", cwd=project_dir)
        else:
            # pasta nao existe, precisa clonar de um remoto
            click.echo("Project doesnt exists, cloning from default remote!")
            clone_svc = mgr.find_service(project)
            if clone_svc is None:
                exit_with_msg(f'No server found having project {project}')
            clone_url = clone_svc.get_git_url(project)
            click.echo(f"Cloning {project} from {clone_svc.NAME}")
            cmd.run(['git', 'clone', clone_url], cwd=cwd)

        # se nao deu certo o clone sai e avisa
        is_git = cmd.output("git rev-parse --git-dir", cwd=project_dir)
        if is_git.is_error():
            exit_with_msg(f'Cloning/Initializing failed, invalid directory {project_dir}')

        _ensure_repos_exists(mgr, project)

        # now sync stuff
        _ensure_remotes(mgr, project, add_remotes)

        branches = cmd.output("git symbolic-ref --short HEAD", cwd=project_dir)
        branch = branches.filter_by(re.compile('^(master|main)$')).get(0, default='main')

        cmd.run(f"git branch -M {branch}", cwd=project_dir)

        remote_branch = cmd.output(f"git ls-remote --exit-code --heads origin {branch}", cwd=project_dir)
        if remote_branch.is_empty():
            cmd.run(f"git push", cwd=project_dir)
        else:
            cmd.run(f"git pull origin {branch}", cwd=project_dir)

        remote_branch = cmd.output(f"git ls-remote --exit-code --heads origin {branch}", cwd=project_dir)
        if remote_branch.is_empty():
            click.echo("You need to create some commit in current branch ({branch}")
            click.echo("to be sent to servers and create the branch there!")
            click.echo("Use:")
            click.echo("$> git add -A")
            click.echo("$> git commit")
            exit_with_msg(f'')

        cmd.run(f'git branch --set-upstream-to=origin/{branch} {branch}', cwd=project_dir)

        if not clone_svc:
            LOG.debug(f"Fetching data from remote!!")
            cmd.run('git fetch --quiet --all --force -v', cwd=project_dir)

        if add_remotes:
            for service in mgr.services.values():
                LOG.debug(f"Forcing push data to services..")
                cmd.run(f'git push -v --force {service.name} {branch}', cwd=project_dir)

        click.echo("Done!")


@cli.command()
@click.argument('projects', nargs=-1)
@click.pass_obj
def create(mgr, projects):
    click.echo("Creating remote projects ..")
    for project in projects:
        click.echo("Processing project {}".format(project))
        for nm, svc in mgr.services.items():
            click.echo("Creating project {} in service: {}".format(project, nm))
            # first, check if project exists
            LOG.info("Checking if repository exists: (%s)", nm)
            exist = svc.get_repo(project)
            if exist:
                LOG.info("Project [%s] already exists. Skipping..", project)
            else:
                LOG.info("Project [%s] doesnt exists. Creating..", project)
                proj = svc.create_repo(project)
                LOG.info("Project sucessfull created!!")
        click.echo("Done!")

@cli.command()
@click.argument('projects', nargs=-1)
@click.option('-c', '--create', 'create', is_flag=True, default=False,
    help='Create project in services if doesnt exists')
@click.pass_obj
def check_remotes(mgr, projects, create):
    click.echo("Checking remotes for projects")
    cwd = Path(mgr.get_basedir()).resolve()
    if not projects:
        LOG.debug(f"Current Directory: {cwd}")
        if cwd.is_dir():
            projects = [cwd.name]
            cwd = cwd.parents[0]
    for project in projects:
        click.echo("Processing folder {}".format(project))
        project_dir = cwd / project
        is_git = cmd.output("git rev-parse --git-dir", cwd=project_dir)
        if is_git.is_error():
            LOG.debug(f"Path {project_dir} is not a git dir. Initializing..")
            #is not a git dir, initialize
            cmd.run("git init", cwd=project_dir)

        clone_svc = mgr.find_service(project)
        if clone_svc is None:
            if create:
                _ensure_repos_exists(mgr, project)
            else:
                exit_with_msg(f'No server found having project {project}')
        clone_svc = mgr.find_service(project)
        if clone_svc is None:
            exit_with_msg(f'No server found having project {project}')
        _ensure_remotes(mgr, project, False, cwd=cwd)


@cli.command(name='list')
@click.argument('services', nargs=-1)
@click.option('-A', '--all', '_all', is_flag=True, default=False)
@click.pass_obj
def _list(mgr, services, _all):
    services = services if len(services) > 0 else 'all'
    services = 'all' if _all else services
    svc_list = mgr.get_services_by_names(services)
    rlist = []
    for svc in svc_list:
        rlist.extend(svc.list_repos())

    for project in sorted(set(rlist)):
        print(project)

@cli.command()
@click.argument('services', nargs=-1)
@click.option('-A', '--all', '_all', is_flag=True, default=False)
@click.pass_obj
def here(mgr, services, _all):
    services = 'all' if _all else services
    svc_list = mgr.get_services_by_names(services)
    cwd = Path.cwd().parents[0]
    project = Path.cwd().name
    project_dir = cwd / project

    # check if it is an git dir
    is_git = cmd.output("git rev-parse --git-dir", cwd=project_dir)
    if is_git.is_error():
        LOG.debug(f"Path {project_dir} is not a git dir. Initializing..")
        #is not a git dir, initialize
        cmd.run("git init", cwd=project_dir)

    # ensure that remote exists
    _ensure_repos_exists(mgr, project)

    # ensure remotes are added
    _ensure_remotes(mgr, project, True, cwd=cwd)


@cli.command()
@click.option('--services', '-s', default='all')
@click.argument('projects', nargs=-1)
@click.pass_obj
def delete(mgr, services, projects):
    try:
        servers = mgr.get_services_by_names(services, error=True)
    except ValueError as snf:
        click.echo(snf)
        return 4

    if not servers:
        exit_with_msg("No remote service selected..")

    for project in projects:
        message = f"Are you sure you want to delete project [{project}] in services:"

        for svc in servers:
            message = message + f"\n\t {svc.NAME}"

        if click.confirm(message+'?'+'\n'):
            for svc in servers:
                click.echo("Removing project {} on server {}".format(project, svc.name))
                svc.delete_repo(project)
                click.echo("Done!")

if __name__ == "__main__":
    cli()
