#!/bin/bash

# $1: artista a buscar
# necesario youtube-dl jshon

# Busca artistas y los muestra ordenados para dejar que el usuario seleccione el correcto. 
# $1= cadena a buscar
function buscar_artista()
{
	json_temp_artistas=$(mktemp)
	curl -q "https://www.syotify.com/search/$1?limit=20" -H 'pragma: no-cache' -H 'accept-encoding: gzip, deflate, sdch' -H 'accept-language: es-ES,es;q=0.8' -H 'user-agent: Mozilla/5.0 (X11; Fedora; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.82 Safari/537.36' -H 'accept: application/json, text/plain, */*' -H 'cache-control: no-cache' -H 'authority: www.syotify.com' -H 'referer: https://www.syotify.com/new-releases' --compressed > json_temp_artistas
	num_resultados=$(cat json_temp_artistas | jshon -e artists -l )
	
	for x in $(seq 0 $(($num_resultados-1)) ) ; do
		echo "$x) " $(cat json_temp_artistas | jshon -e artists -e $x -e name -u)
	done
	
	if [[ $num_resultados == 0 ]] ; then
		id_artista_seleccionado=0
	else
		read -p "Introduce el id del artista deseado ( 0 - $(($num_resultados-1)) ) " id_artista_seleccionado
	fi
	buscar_discografia $(cat json_temp_artistas | jshon -e artists -e $id_artista_seleccionado -e name -u)
}

# Busca todos los albumes del artista pasado por parametro
# $1= artista
function buscar_discografia()
{
	json_temp_albums=$(mktemp)
	curl -q 'https://www.syotify.com/get-artist?top-tracks=true' -H 'origin: https://www.syotify.com' -H 'accept-encoding: gzip, deflate' -H 'accept-language: es-ES,es;q=0.8' -H 'pragma: no-cache' -H 'user-agent: Mozilla/5.0 (X11; Fedora; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.82 Safari/537.36' -H 'content-type: application/json;charset=UTF-8' -H 'accept: application/json, text/plain, */*' -H 'cache-control: no-cache' -H 'authority: www.syotify.com' -H 'referer: https://www.syotify.com/search/extremoduro' --data-binary '{"name":"'$1'"}' --compressed > json_temp_albums
	num_albums=$(cat json_temp_albums | jshon -e albums -l )
	for x in $(seq 0 $(($num_albums-1)) ) ; do
		echo "$x) " $(cat json_temp_albums | jshon -e albums -e $x -e name -u)
	done
	
	echo "$num_albums) Descargar la discografía entera"
	
	read -p "Introduce el id del album a descargar (0 - $num_albums) " id_album_seleccionado
	descargar_album $id_album_seleccionado
}

# Descarga el album que se le pasa por parametro. Lo que se pasa es el id relativo al archivo json_temp_albums
# $1= id album
function descargar_album()
{
	nombre_artista=$(cat json_temp_albums | jshon -e name -u)
	num_albums=$(cat json_temp_albums | jshon -e albums -l )
	if [[ $1 -lt $num_albums ]] ; then
		num_canciones=$(cat json_temp_albums | jshon -e albums -e $1 -e tracks -l)
		nombre_album=$(cat json_temp_albums | jshon -e albums -e $1 -e name -u)
		mkdir -p "$nombre_artista/$nombre_album"
		for x in $( seq 0 $(($num_canciones-1)) ) ; do
			nombre_cancion=$(cat json_temp_albums | jshon -e albums -e $1 -e tracks -e $x -e name -u)
			id_youtube=$(curl -q "https://www.syotify.com/search-audio/$nombre_artista/$nombre_cancion" -H 'pragma: no-cache' -H 'accept-encoding: gzip, deflate, sdch' -H 'accept-language: es-ES,es;q=0.8' -H 'user-agent: Mozilla/5.0 (X11; Fedora; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.82 Safari/537.36' -H 'accept: application/json, text/plain, */*' -H 'cache-control: no-cache' -H 'authority: www.syotify.com' -H "referer: https://www.syotify.com/artist/$nombre_artista" --compressed | jshon -e id -u)
			descargar_cancion "$id_youtube" "$nombre_cancion" "$nombre_artista/$nombre_album"
		done
	else	#descargar todos
	
		for y in $( seq 0 $(($1-1)) ) ; do
			descargar_album $y
		done
		
	fi


}

# Descarga la cancion de youtube
# $1= id_youtube
# $2=nombre cancion
# $3= path destino
# 
function descargar_cancion()
{
	echo "[$1] Descargando $2"
	youtube-dl -q --audio-format "mp3" --id -x $1
	# Editar etiquetas id3
	mv $1.mp3 "$3/$2.mp3"
}


if [[ $# == 1 ]] ; then
	buscar_artista $1
else
	read -p "Artista a buscar? " artista
	buscar_artista $artista
fi
