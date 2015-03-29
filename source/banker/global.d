module global;
import ESQpatch;

ESQ_Bank *active_bank()
{
  return global_bank;
}

ESQ_Program *active_program()
{
  return &global_bank.patches[active_program_number];
}

__gshared uint active_program_number = 0;
__gshared ESQ_Bank *global_bank;

shared static this()
{
  global_bank = new ESQ_Bank;
  *global_bank = ESQ_default_bank;
}
