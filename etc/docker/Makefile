all: libosmium

libosmium:
	( echo "FROM debian:buster"; tail -n +2 libosmium-debian9 ) > libosmium-debian10
	( echo "FROM ubuntu:xenial"; tail -n +2 libosmium-debian9 ) > libosmium-ubuntu16
	( echo "FROM ubuntu:bionic"; tail -n +2 libosmium-debian9 ) > libosmium-ubuntu18

