library directcode.build;

import "dart:async";
import "dart:convert";
import "dart:io";

class TeamCity {
  static TeamCityBlock openBlock(String name) => new TeamCityBlock(name)..open();

  static void serviceMessage(String value, Map<String, String> input) {
    var keyz = input.keys.map((it) {
      var v = input[it];
      return "${it}='${v}'";
    }).toList();
    print("##teamcity[${value} ${keyz.join(' ')}]");
  }

  static Future inBlock(String name, action()) {
    var tcBlock = openBlock(name);
    var r = action();
    if (r is Future) {
      return r.then((_) {
        tcBlock.close();
      });
    } else {
      tcBlock.close();
      return new Future.value();
    }
  }
}

class TeamCityBlock {
  final String name;

  TeamCityBlock(this.name);

  void open() {
    TeamCity.serviceMessage("blockOpened", {
      "name": name
    });
  }

  void close() {
    TeamCity.serviceMessage("blockClosed", {
      "name": name
    });
  }

  @override
  String toString() => name;
}

Future block(String name, action()) {
  return TeamCity.inBlock(name, action);
}

class HTTP {
  static HttpClient client = new HttpClient();

  static Future<String> getString(String url) {
    return client.getUrl(Uri.parse(url)).then((request) {
      return request.close();
    }).then((response) {
      var data = response.transform(UTF8.decoder).join();
      new Future(() {
        client.close();
        client = new HttpClient();
      });
      return data;
    });
  }

  static Future<File> downloadFile(String url, File file) {
    return client.getUrl(Uri.parse(url)).then((request) {
      return request.close();
    }).then((response) {
      var p = response.pipe(file.openWrite());
      new Future(() {
        client.close();
        client = new HttpClient();
      });
      return p;
    }).then((_) {
      return file;
    });
  }
}

void inheritIO(Process process, {String prefix, bool lineBased: true}) {
  if (lineBased) {
    process.stdout.transform(UTF8.decoder).transform(new LineSplitter()).listen((String data) {
      if (prefix != null) {
        stdout.write(prefix);
      }
      stdout.writeln(data);
    });

    process.stderr.transform(UTF8.decoder).transform(new LineSplitter()).listen((String data) {
      if (prefix != null) {
        stderr.write(prefix);
      }
      stderr.writeln(data);
    });
  } else {
    process.stdout.listen((data) => stdout.add(data));
    process.stderr.listen((data) => stderr.add(data));
  }
}

Future executeCommands(List<String> commands) {
  var future = new Future.value();

  for (var command in commands) {
    var split = command.split(" ");
    var executable = split.removeAt(0);


    future = future.then((value) {
      bool allowExitCodeOne = false;

      if (executable.startsWith("@")) {
        allowExitCodeOne = true;
        executable = executable.substring(1);
      }

      return Process.start(executable, split).then((process) {
        inheritIO(process);

        return process.exitCode;
      }).then((exitCode) {
        if (exitCode != 0 && (allowExitCodeOne ? exitCode != 1 : true)) {
          print("Command '${command}' exited with exit code ${exitCode}");
          exit(1);
        }
      });
    });
  }

  return future;
}

Future script(String path, [List<String> args]) {
  var argz = args != null ? " ${args.join(' ')}" : "";
  return executeCommand("dart ${path}${argz}");
}

File file(String path) => new File(path);
Directory directory(String path) => new Directory(path);

FileSystemEntity fsEntity(String path) {
  if (isFile(path)) return file(path);
  if (isDirectory(path)) return directory(path);
  if (isLink(path)) return link(path);
  return null;
}

bool exists(String path) => FileSystemEntity.typeSync(path) != FileSystemEntityType.NOT_FOUND;
bool isFile(String path) => FileSystemEntity.isFileSync(path);
bool isDirectory(String path) => FileSystemEntity.isDirectorySync(path);
bool isLink(String path) => FileSystemEntity.isLinkSync(path);
void symlink(String target, String linkName) => new Link(linkName).createSync(target, recursive: true);
Link link(String path) => new Link(path);
void write(String path, String content) => file(path).writeAsStringSync(content);
void delete(String path) => fsEntity(path).deleteSync();

Future pub(String args) {
  return executeCommand("pub ${args}");
}

Future executeCommand(String command) => executeCommands([command]);
