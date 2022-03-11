#! /bin/bash

tag=$1
sep='-'

# split string into array by separator
arr=($(echo ${tag} | tr ${sep} '\n'))

# loop over array and append
sub=''
for index in ${!arr[@]}
do
    sub+="${arr[index]}"
    docker build -t c7huang/devel:${sub} -f ${sub}.dockerfile .
    sub+="${sep}"
done
