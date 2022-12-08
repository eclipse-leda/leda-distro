# OSS Compliance Check

Tool: https://github.com/oss-review-toolkit/ort

## Building ORT

As ORT does not have public docker container released, we need to build the containers first:

    git clone https://github.com/oss-review-toolkit/ort
    cd ort
    scripts/docker_build.sh


## Using ORT

    cd $WORKSPACE
    docker run -v $(pwd):/project ort --help
    docker run -v $(pwd):/project ort analyze --help
    docker run -v $(pwd):/project -v $(pwd)/.ort:/home/ort/.ort ort --info analyze --ort-curations -f JSON -i /project -o /project/ort/analyzer



