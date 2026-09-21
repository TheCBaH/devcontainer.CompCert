type form = {
  mnemonic : string;
  opcode : int;
  funct3 : int;
  funct7 : int;
  rv64_only : bool;
  source : string;
}

let forms =
  [
    {
      mnemonic = "mul";
      opcode = 0x33;
      funct3 = 0;
      funct7 = 0x01;
      rv64_only = false;
      source = "rv_m/mul";
    };
    {
      mnemonic = "remu";
      opcode = 0x33;
      funct3 = 7;
      funct7 = 0x01;
      rv64_only = false;
      source = "rv_m/remu";
    };
    {
      mnemonic = "mulw";
      opcode = 0x3b;
      funct3 = 0;
      funct7 = 0x01;
      rv64_only = true;
      source = "rv64_m/mulw";
    };
  ]

let find mnemonic = List.find_opt (fun f -> String.equal f.mnemonic mnemonic) forms

let component : Target_component.t =
  {
    id = "riscv.m";
    feature = "m";
    summary = "integer multiply: mul, remu, and RV64 mulw";
    forms =
      List.map
        (fun f ->
          {
            Target_component.label = f.mnemonic;
            mnemonics = [ f.mnemonic ];
            sources = [ { upstream = "riscv-opcodes"; name = f.source } ];
          })
        forms;
  }
