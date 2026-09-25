type t = {
  source : string;
  target : Target.t;
  extension : string;
  native_name : string option;
  reason : string;
  probe : string;
}

let template ~target ~native_name ~spellings =
  {
    source = "riscv_opcodes";
    target;
    extension = "rv_zimop";
    native_name = Some native_name;
    reason = "template-not-a-mnemonic";
    probe =
      Printf.sprintf
        "riscv64-linux-gnu-as 2.44, -march=rv64im_zimop: unrecognized opcode `%s'; the template's \
         concrete spellings %s are each their own promoted record"
        (String.lowercase_ascii native_name)
        spellings;
  }

let all =
  [
    {
      source = "riscv_opcodes";
      target = Target.Riscv32;
      extension = "rv_zicfiss";
      native_name = None;
      reason = "gas-lacks-zicfiss";
      probe =
        "riscv32-linux-gnu-as 2.43.1 (crosstool-NG 1.27.0), -march=rv32im_zimop_zicfiss: unknown \
         prefixed ISA extension `zicfiss' (riscv64-linux-gnu-as 2.44 accepts it)";
    };
  ]
  @ List.concat_map
      (fun target ->
        [
          template ~target ~native_name:"mop.r.N" ~spellings:"mop.r.0..mop.r.31";
          template ~target ~native_name:"mop.rr.N" ~spellings:"mop.rr.0..mop.rr.7";
        ])
      [ Target.Riscv32; Target.Riscv64 ]

let find ~source target ~extension =
  List.find_opt
    (fun u ->
      u.source = source && u.target = target && u.extension = extension && u.native_name = None)
    all

let find_record ~source target ~extension ~native_name =
  List.find_opt
    (fun u ->
      u.source = source && u.target = target && u.extension = extension
      && u.native_name = Some native_name)
    all
