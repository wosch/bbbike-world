all: libosmium

libosmium:
	( echo "FROM debian:bullseye"; tail -n +2 libosmium-debian10 ) > libosmium-debian11
	( echo "FROM ubuntu:bionic";   tail -n +2 libosmium-debian10 ) > libosmium-ubuntu18
	( echo "FROM ubuntu:focal";    tail -n +2 libosmium-debian10 ) > libosmium-ubuntu20

