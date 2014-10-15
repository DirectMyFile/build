import "common.dart";

void main() {
  buildScript();
}

void buildScript() {
  block("Build Script", () {
    write("test.dart", """
    void main() {
      print("Hello World");
    }
    """);
    
    return script("test.dart");
  }).then((_) {
    delete("test.dart");
  });
}