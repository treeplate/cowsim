T foo<T>(T arg) {
  print(arg);
  return arg;
}

void main() {
  foo(print(foo<void>(3) as dynamic));
}
