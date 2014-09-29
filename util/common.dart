library directcode.build;

import "dart:async";
import "dart:convert";
import "dart:io";

class TeamCity {
  static TeamCityBlock openBlock(String name) =>
      new TeamCityBlock(name)..open();

  static void serviceMessage(String value, Map<String, String> input) {
    var keyz = input.keys.map((it) {
      var v = input[it];
      return "${it}='${v}'";
    }).toList();
    print("##teamcity[${value} ${keyz.join(' ')}]");
  }

  static dynamic inBlock(String name, action()) {
    var block = openBlock(name);
    var r = action();
    if (r is Future) {
      return r.then((_) {
        block.close();
      });
    } else {
      return new Future.value();
    }
  }
}

class TeamCityBlock {
  final String name;

  TeamCityBlock(this.name);

  void open() {
    TeamCity.serviceMessage("blockOpened", {
      "name": "name"
    });
  }

  void close() {
    TeamCity.serviceMessage("blockClosed", {
      "name": "name"
    });
  }

  @override
  String toString() => name;
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

Future executeCommand(String command) => executeCommands([command]);
