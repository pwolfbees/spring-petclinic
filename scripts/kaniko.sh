# /busybox/sh 

if [ $# -ne 3 ];
    then echo "Usage: kaniko.sh -p <path to Dockerfile> <context directory> <image tag 1>...<image tag N>"
fi

cmd="/kaniko/executor -f $1 -c $2"

for i in "${@:3}"; do
    cmd="${cmd} -d $i"
done

$cmd