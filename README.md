# Docker Build Example
An example of how one can build a docker image from a small java project. The project has resource file in a sub folder which should be copied to the docker image.

The project was created to find a workaround to the `Unable to prepare context`-error sometimes encountered when [building docker images in a OneDrive path](https://github.com/docker/for-win/issues/1290).

## Build steps
The script `docker-build.sh` will compile the java project in indicated when starting the script and package it into a jar-file. This application uses files from the `/resource`-folder. The jar-file and resources are copied to the docker image.

In order to circumvent the `Unable to prepare context`-error the files which the docker build command needs to access cannot be located in a folder locked by other processes (OneDrive). It seems creating a new folder in OneDrive is enough. If not, I recommend a temporary folder in the home directory (e.g. c:/Users/the_user/).

The build script will, by default, create two temporary folders. One target path ("./TEMP_TARGET") for the java build and one path for the creating docker context ("./DOCKER_BUILD_TEMP/"). The folder paths can be changed when running the script.

**_!!! NOTE: THE TEMPORARY FOLDERS WILL BE REMOVED AFTER THE SCRIPT IS FINISHED !!!_**

## Running the example
The `docker-build.sh` script has been run in git-bash/docker quick start terminal on Windows 10.

From the project's root folder run:

```bash
$ ./docker-build.sh Main.java
$ docker run java_app
```
For building a simple application residing in the project root, together with a manifest.txt in the same folder, or:
 
 ```bash
 $ ./docker-build.sh -s ./src -p com.custom_docker_context -m ./src/manifest_w_package.txt Main.java
 ```
For a project where the main `*.java` is located in a sub path as well as the manifest file, omitting `-m` will have the script look for manifest.txt in the project's root path.

```bash
$ ./docker-build.sh -h
```
Will reveal the options where one can change the name of the application, and thereby the docker image. It is also possible to change the name and/or paths of the temporary folders, manifest file, source path, main package, and the resource path.