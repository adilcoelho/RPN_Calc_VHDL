library verilog;
use verilog.vl_types.all;
entity rpn is
    port(
        clk             : in     vl_logic;
        opButtons       : in     vl_logic_vector(2 downto 0);
        numberSwitches  : in     vl_logic_vector(3 downto 0);
        ssd_saida       : out    vl_logic_vector(27 downto 0)
    );
end rpn;
