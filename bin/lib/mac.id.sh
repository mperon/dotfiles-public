#!/usr/bin/env bash

MAC_HW_MODEL=$(sysctl hw.model | cut -d" " -f2)
MAC_ARCH="Intel" MAC_MODEL= MAC_SIZE= MAC_YEAR=
case "$MAC_HW_MODEL" in
    "Mac14,2") MAC_MODEL="MacBook Air" MAC_SIZE="13" MAC_YEAR="2022" MAC_ARCH="M2";;
    "Mac14,7") MAC_MODEL="MacBook Pro" MAC_SIZE="13" MAC_YEAR="2022" MAC_ARCH="M2";;
    "MacBookAir10,1") MAC_MODEL="MacBook Air" MAC_SIZE="13" MAC_YEAR="2020" MAC_ARCH="M1" ;;
    "MacBookAir2,1") MAC_MODEL="MacBook Air" MAC_SIZE="13" MAC_YEAR="2009" ;;
    "MacBookAir3,1") MAC_MODEL="MacBook Air" MAC_SIZE="11" MAC_YEAR="2010" ;;
    "MacBookAir3,2") MAC_MODEL="MacBook Air" MAC_SIZE="13" MAC_YEAR="2010" ;;
    "MacBookAir4,1") MAC_MODEL="MacBook Air" MAC_SIZE="11" MAC_YEAR="2011" ;;
    "MacBookAir4,2") MAC_MODEL="MacBook Air" MAC_SIZE="13" MAC_YEAR="2011" ;;
    "MacBookAir5,1") MAC_MODEL="MacBook Air" MAC_SIZE="11" MAC_YEAR="2012" ;;
    "MacBookAir5,2") MAC_MODEL="MacBook Air" MAC_SIZE="13" MAC_YEAR="2012" ;;
    "MacBookAir6,1") MAC_MODEL="MacBook Air" MAC_SIZE="11" MAC_YEAR="2013" ;;
    "MacBookAir6,1") MAC_MODEL="MacBook Air" MAC_SIZE="11" MAC_YEAR="2014" ;;
    "MacBookAir6,2") MAC_MODEL="MacBook Air" MAC_SIZE="13" MAC_YEAR="2013" ;;
    "MacBookAir6,2") MAC_MODEL="MacBook Air" MAC_SIZE="13" MAC_YEAR="2014" ;;
    "MacBookAir7,1") MAC_MODEL="MacBook Air" MAC_SIZE="11" MAC_YEAR="2015" ;;
    "MacBookAir7,2") MAC_MODEL="MacBook Air" MAC_SIZE="13" MAC_YEAR="2015" ;;
    "MacBookAir7,2") MAC_MODEL="MacBook Air" MAC_SIZE="13" MAC_YEAR="2017" ;;
    "MacBookAir8,1") MAC_MODEL="MacBook Air" MAC_SIZE="13" MAC_YEAR="2018" ;;
    "MacBookAir8,2") MAC_MODEL="MacBook Air" MAC_SIZE="13" MAC_YEAR="2019" ;;
    "MacBookAir9,1") MAC_MODEL="MacBook Air" MAC_SIZE="13" MAC_YEAR="2020" ;;
    "MacBookPro10,1") MAC_MODEL="MacBook Pro" MAC_SIZE="15" MAC_YEAR="2012" ;;
    "MacBookPro10,1") MAC_MODEL="MacBook Pro" MAC_SIZE="15" MAC_YEAR="2013" ;;
    "MacBookPro10,2") MAC_MODEL="MacBook Pro" MAC_SIZE="13" MAC_YEAR="2012" ;;
    "MacBookPro10,2") MAC_MODEL="MacBook Pro" MAC_SIZE="13" MAC_YEAR="2013" ;;
    "MacBookPro11,1") MAC_MODEL="MacBook Pro" MAC_SIZE="13" MAC_YEAR="2013" ;;
    "MacBookPro11,1") MAC_MODEL="MacBook Pro" MAC_SIZE="13" MAC_YEAR="2014" ;;
    "MacBookPro11,2") MAC_MODEL="MacBook Pro" MAC_SIZE="15" MAC_YEAR="2013" ;;
    "MacBookPro11,2") MAC_MODEL="MacBook Pro" MAC_SIZE="15" MAC_YEAR="2014" ;;
    "MacBookPro11,3") MAC_MODEL="MacBook Pro" MAC_SIZE="15" MAC_YEAR="2013" ;;
    "MacBookPro11,3") MAC_MODEL="MacBook Pro" MAC_SIZE="15" MAC_YEAR="2014" ;;
    "MacBookPro11,4") MAC_MODEL="MacBook Pro" MAC_SIZE="15" MAC_YEAR="2015" ;;
    "MacBookPro11,5") MAC_MODEL="MacBook Pro" MAC_SIZE="15" MAC_YEAR="2015" ;;
    "MacBookPro12,1") MAC_MODEL="MacBook Pro" MAC_SIZE="13" MAC_YEAR="2015" ;;
    "MacBookPro13,1") MAC_MODEL="MacBook Pro" MAC_SIZE="13" MAC_YEAR="2016" ;;
    "MacBookPro13,2") MAC_MODEL="MacBook Pro" MAC_SIZE="13" MAC_YEAR="2016" ;;
    "MacBookPro13,3") MAC_MODEL="MacBook Pro" MAC_SIZE="15" MAC_YEAR="2016" ;;
    "MacBookPro14,1") MAC_MODEL="MacBook Pro" MAC_SIZE="13" MAC_YEAR="2017" ;;
    "MacBookPro14,2") MAC_MODEL="MacBook Pro" MAC_SIZE="13" MAC_YEAR="2017" ;;
    "MacBookPro14,3") MAC_MODEL="MacBook Pro" MAC_SIZE="15" MAC_YEAR="2017" ;;
    "MacBookPro15,1") MAC_MODEL="MacBook Pro" MAC_SIZE="15" MAC_YEAR="2018" ;;
    "MacBookPro15,1") MAC_MODEL="MacBook Pro" MAC_SIZE="15" MAC_YEAR="2019" ;;
    "MacBookPro15,2") MAC_MODEL="MacBook Pro" MAC_SIZE="13" MAC_YEAR="2018" ;;
    "MacBookPro15,2") MAC_MODEL="MacBook Pro" MAC_SIZE="13" MAC_YEAR="2019" ;;
    "MacBookPro15,3") MAC_MODEL="MacBook Pro" MAC_SIZE="15" MAC_YEAR="2019" ;;
    "MacBookPro15,4") MAC_MODEL="MacBook Pro" MAC_SIZE="13" MAC_YEAR="2019" ;;
    "MacBookPro16,1") MAC_MODEL="MacBook Pro" MAC_SIZE="16" MAC_YEAR="2019" ;;
    "MacBookPro16,2") MAC_MODEL="MacBook Pro" MAC_SIZE="13" MAC_YEAR="2020" ;;
    "MacBookPro16,3") MAC_MODEL="MacBook Pro" MAC_SIZE="13" MAC_YEAR="2020" ;;
    "MacBookPro16,4") MAC_MODEL="MacBook Pro" MAC_SIZE="16" MAC_YEAR="2019" ;;
    "MacBookPro17,1") MAC_MODEL="MacBook Pro" MAC_SIZE="13" MAC_YEAR="2020" MAC_ARCH="M1";;
    "MacBookPro18,1") MAC_MODEL="MacBook Pro" MAC_SIZE="16" MAC_YEAR="2021" MAC_ARCH="M1";;
    "MacBookPro18,2") MAC_MODEL="MacBook Pro" MAC_SIZE="16" MAC_YEAR="2021" MAC_ARCH="M1";;
    "MacBookPro18,3") MAC_MODEL="MacBook Pro" MAC_SIZE="14" MAC_YEAR="2021" MAC_ARCH="M1";;
    "MacBookPro18,4") MAC_MODEL="MacBook Pro" MAC_SIZE="14" MAC_YEAR="2021" MAC_ARCH="M1";;
    "MacBookPro4,1") MAC_MODEL="MacBook Pro" MAC_SIZE="15" MAC_YEAR="2008" ;;
    "MacBookPro4,1") MAC_MODEL="MacBook Pro" MAC_SIZE="17" MAC_YEAR="2008" ;;
    "MacBookPro5,1") MAC_MODEL="MacBook Pro" MAC_SIZE="15" MAC_YEAR="2008" ;;
    "MacBookPro5,2") MAC_MODEL="MacBook Pro" MAC_SIZE="17" MAC_YEAR="2009" ;;
    "MacBookPro5,2") MAC_MODEL="MacBook Pro" MAC_SIZE="17" MAC_YEAR="2009" ;;
    "MacBookPro5,3") MAC_MODEL="MacBook Pro" MAC_SIZE="15" MAC_YEAR="2009" ;;
    "MacBookPro5,3") MAC_MODEL="MacBook Pro" MAC_SIZE="15" MAC_YEAR="2009" ;;
    "MacBookPro5,5") MAC_MODEL="MacBook Pro" MAC_SIZE="13" MAC_YEAR="2009" ;;
    "MacBookPro6,1") MAC_MODEL="MacBook Pro" MAC_SIZE="17" MAC_YEAR="2010" ;;
    "MacBookPro6,2") MAC_MODEL="MacBook Pro" MAC_SIZE="15" MAC_YEAR="2010" ;;
    "MacBookPro7,1") MAC_MODEL="MacBook Pro" MAC_SIZE="13" MAC_YEAR="2010" ;;
    "MacBookPro8,1") MAC_MODEL="MacBook Pro" MAC_SIZE="13" MAC_YEAR="2011" ;;
    "MacBookPro8,1") MAC_MODEL="MacBook Pro" MAC_SIZE="13" MAC_YEAR="2011" ;;
    "MacBookPro8,2") MAC_MODEL="MacBook Pro" MAC_SIZE="15" MAC_YEAR="2011" ;;
    "MacBookPro8,2") MAC_MODEL="MacBook Pro" MAC_SIZE="15" MAC_YEAR="2011" ;;
    "MacBookPro8,3") MAC_MODEL="MacBook Pro" MAC_SIZE="17" MAC_YEAR="2011" ;;
    "MacBookPro8,3") MAC_MODEL="MacBook Pro" MAC_SIZE="17" MAC_YEAR="2011" ;;
    "MacBookPro9,1") MAC_MODEL="MacBook Pro" MAC_SIZE="15" MAC_YEAR="2012" ;;
    "MacBookPro9,2") MAC_MODEL="MacBook Pro" MAC_SIZE="13" MAC_YEAR="2012" ;;
	*) MAC_MODEL= MAC_SIZE= MAC_YEAR= MAC_ARCH=;;
esac
