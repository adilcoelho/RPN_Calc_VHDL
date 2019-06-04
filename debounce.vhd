library ieee;
use ieee.std_logic_1164.all;

ENTITY debounce IS
	GENERIC(
				time_ms : integer := 100;
				freq_clk: integer := 50e6
	);
	PORT(
		  button : in std_logic;
		  clk : in std_logic;
		  debounced_out : out std_logic
	);
END ENTITY;

ARCHITECTURE arch OF debounce IS
	CONSTANT counter_max: integer := time_ms * (freq_clk / 1e3);
BEGIN

	PROCESS (clk, button)
	VARIABLE counter: integer := 0;
	VARIABLE saida: std_logic := '0'; 
	BEGIN
		IF button = saida THEN
			counter := 0;
		ELSIF clk'event and clk = '1' THEN
			IF counter < counter_max THEN
				counter := counter + 1;
			ELSE
				saida := not saida;
			END IF;
		END IF;
		debounced_out <= saida;
	END PROCESS;

END ARCHITECTURE;
