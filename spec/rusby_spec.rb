describe Rusby::Rust do
  subject { described_class.new('i32') }

  it 'converts simple assignment' do
    ast = Parser::Ruby22.parse('j = 2')
    expect(subject.generate(ast)).to eq('let mut j = 2;')
  end

  it 'converts array index assignment' do
    ast = Parser::Ruby22.parse('a = []; i = 0; a[i] = 5')
    expect(subject.generate(ast)).to eq("let mut a = Vec::new();\nlet mut i = 0;\na[i as usize]=5")
  end

  it 'converts multiple assignment' do
    ast = Parser::Ruby22.parse('i = 1; j = 2;  i, j = [j, i]')
    expect(subject.generate(ast)).to eq([
      'let mut i = 1;',
      'let mut j = 2;',
      'let lv0 = j;',
      'let lv1 = i;',
      'i = lv0;',
      'j = lv1;'
    ].join("\n"))
  end

  it 'converts if operator' do
    ast = Parser::Ruby22.parse('if 3 > 2; true; end')
    expect(subject.generate(ast)).to eq("if 3>2 {\ntrue\n}\n")
  end

  it 'converts unless operator' do
    ast = Parser::Ruby22.parse('unless 3 > 2; true; end')
    expect(subject.generate(ast)).to eq("if !(3>2) {\ntrue\n}\n")
  end

  it 'converts postfix if operator' do
    ast = Parser::Ruby22.parse('return 5 if 2 >= 1')
    expect(subject.generate(ast)).to eq("if 2>=1 {\nreturn 5 as i32;\n}\n")
  end

  it 'converts postfix unless operator' do
    ast = Parser::Ruby22.parse('return 5 unless 2 >= 1')
    expect(subject.generate(ast)).to eq("if !(2>=1) {\nreturn 5 as i32;\n}\n")
  end

  it 'converts loop operator' do
    ast = Parser::Ruby22.parse('loop do; true; end')
    expect(subject.generate(ast)).to eq("loop {\ntrue\n}")
  end

  it 'converts while operator' do
    ast = Parser::Ruby22.parse('while 5 < 6 do; true; end')
    expect(subject.generate(ast)).to eq("while 5<6 {\ntrue\n}")
  end

  it 'converts postfix while operator' do
    ast = Parser::Ruby22.parse('begin; false; end while 3 > 2')
    expect(subject.generate(ast)).to eq("while {\nfalse;\n3>2\n}{}")
  end

  it 'converts puts' do
    ast = Parser::Ruby22.parse('puts "test message"')
    expect(subject.generate(ast)).to eq("\nprintln!(\"{}\", \"test message\");io::stdout().flush().unwrap();\n")
  end

  it 'understands meta commands' do
    ast = Parser::Ruby22.parse("rust_variable 'my_var'; my_var = 123")
    expect(subject.generate(ast)).to eq("\nmy_var = 123;")
  end

  it 'supports matrix index assignment' do
    ast = Parser::Ruby22.parse <<-eos
      rust_variable "m"
      m[2][3] = 123
    eos
    expect(subject.generate(ast)).to eq("\nm[2 as usize][3 as usize]=123")
  end
end
