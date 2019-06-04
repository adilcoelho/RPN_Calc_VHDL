library verilog;
use verilog.vl_types.all;
entity rpn_vlg_sample_tst is
    port(
        clk             : in     vl_logic;
        numberSwitches  : in     vl_logic_vector(3 downto 0);
        opButtons       : in     vl_logic_vector(2 downto 0);
        sampler_tx      : out    vl_logic
    );
end rpn_vlg_sample_tst;
