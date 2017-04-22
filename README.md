# Dockas Development Environment

To run this environment you gonna need the following dependencies:

* docker (>= 1.13.0)
* docker-machine (>= 0.9.0)
* docker-compose (>= 1.9.0)
* virtualbox (>= 5.0)
* make (>= 3.81)

Maybe some day i provide a script to install all this dependencies in Ubuntu system.


Clone this repo using the command:

```
git clone --recursive git@github.com:dockas/dockas_devenv.git
```

where `recursive` is required to clone all submodules. After that, run the following:

```bash
make up
```

This command going to create a new docker-machine named `dockas-1`, create the docker-compose.yml config file and start the containers in a controlled way (there are dependencies between containers).

To track some container logs, run the command:

```
make logs srv=api_rest
```

passing the container name (service) as the srv param.

**Warning**

You must authorize the urls because we use self signed SSL certificates in development mode:

https://api.dockas.dev/v1/auth/signed
https://socket.dockas.dev/
https://dockas.dev