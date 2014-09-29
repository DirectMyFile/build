library teamcity;

class TeamCity {
  static Block openBlock(String name) =>
      new Block(name)..open();

  static void serviceMessage(String value, Map<String, String> input) {
    var keyz = input.keys.map((it) {
      var v = input[it];
      return "${it}='${v}'";
    }).toList();
    print("##teamcity[${value} ${keyz.join(' ')}]");
  }

  static void inBlock(String name, void action()) {
    var block = openBlock(name);
    action();
    block.close();
  }
}

class Block {
  final String name;

  Block(this.name);

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
