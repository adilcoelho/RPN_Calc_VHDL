library verilog;
use verilog.vl_types.all;
entity rpn_vlg_check_tst is
    port(
        ssd_saida       : in     vl_logic_vector(27 downto 0);
        sampler_rx      : in     vl_logic
    );
end rpn_vlg_check_tst;
