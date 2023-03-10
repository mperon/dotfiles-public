import os
import gi
gi.require_version('Nautilus', '3.0')
from gi.repository import Nautilus, GObject, Gtk, Gdk

_FILENAME_FORMAT = ("IMAGEM-{0:03d}.jpg", "TEXTO-{0:03d}.txt")

class ClipBoardPasteImage(GObject.GObject, Nautilus.MenuProvider):

    def __init__(self):
        self.clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD)

    def menu_activate_cb(self, menu, file):
        if not self.try_paste_image(file):
            self.try_paste_text(file)


    def define_menu_helper(self, name, window, files):
        if (isinstance(files, list)):
            if len(files) != 1:
                return
            else:
                file = files[0]
        else:
            file = files

        if not file.is_directory() or file.get_uri_scheme() != 'file':
            return

        item = Nautilus.MenuItem(name="ClipBoardPasteImage::" + name,
            label="Paste Clipboard Here",
            tip='Paste', icon='')
        item.connect('activate', self.menu_activate_cb, file)
        return [item]

    def get_background_items(self, window, file):
        return self.define_menu_helper("Background", window, file)

    def get_file_items(self, window, files):
        return self.define_menu_helper("File", window, files)


    def try_paste_image(self, file):
        image = self.clipboard.wait_for_image()
        fpath = self.get_path(file)
        if image is not None:
            name = self.find_name(fpath, _FILENAME_FORMAT[0])
            newpath = os.path.join(fpath, name)
            image.savev(newpath, "jpeg", ["quality"], ["85"])
            return True
        return False

    def try_paste_text(self, file):
        text = self.clipboard.wait_for_text()
        fpath = self.get_path(file)
        if text is not None:
            name = self.find_name(fpath, _FILENAME_FORMAT[1])
            newpath = os.path.join(fpath, name)
            with open(newpath, "w") as text_file:
                text_file.write(text)

    def get_path(self, file):
        return file.get_location().get_path()


    def find_name(self, path, str_format):
        for i in range(1,500):
            file_path = str_format.format(i)
            if (not os.path.exists(os.path.join(path, file_path))):
                return file_path