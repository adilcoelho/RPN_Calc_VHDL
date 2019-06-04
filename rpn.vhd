library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY rpn IS
	GENERIC(
        NUMDISPLAYS: integer := 4;
        N_BITS_NUM: integer := 4; -- pi
		NUM_MEMORY: integer := 4;  -- numero limite para tamanho da pilha
        CMD_DEBOUNCE_T_MS: integer := 5; --700;
        FCLK: integer := 1000 ---50e6
	);
	PORT(
        clk: in std_logic;
        opButtons: in std_logic_vector(2 downto 0);
        numberSwitches: in std_logic_vector(N_BITS_NUM - 1 downto 0);
		ssd_saida: out std_logic_vector (NUMDISPLAYS*7 - 1 downto 0)
	);
END ENTITY;

ARCHITECTURE arch OF rpn IS
	COMPONENT debounce IS
		GENERIC(
				time_ms : integer := 2; ---100;
				freq_clk: integer := FCLK--- 50e6
		);
		PORT(
  		  button : in std_logic;
		  clk : in std_logic;
		  debounced_out : out std_logic
		);
    END COMPONENT;
-------------------------------------------------------------------------------------
type memory is array(0 to NUM_MEMORY - 1) of integer;
signal reg: memory;

signal numIn: std_logic_vector(N_BITS_NUM - 1 downto 0);
signal calcResult: integer range 0 to 2 ** N_BITS_NUM;

signal resultado: std_logic_vector(NUMDISPLAYS*7 - 1 downto 0); -- Adicionado para converter o integer
type hexa is array (NUMDISPLAYS-1 downto 0) of std_logic_vector(3 downto 0);
signal hex: hexa;

signal opIn: std_logic_vector(2 downto 0);

signal regsRst, opAq, didEnter: std_logic;

CONSTANT opCounterMax: integer := CMD_DEBOUNCE_T_MS * FCLK / 1e3;
--------------------------------------------------------------------------------------
BEGIN
	debounce_operation_2 : debounce port map(button => not opButtons(2), clk => clk, debounced_out => opIn(2));
	debounce_operation_1 : debounce port map(button => not opButtons(1), clk => clk, debounced_out => opIn(1));
	debounce_operation_0 : debounce port map(button => not opButtons(0), clk => clk, debounced_out => opIn(0));

    number_dbc_gen: for i in 0 to N_BITS_NUM - 1 generate
    	number_dbc_X: debounce port map(button => numberSwitches(i), clk => clk, debounced_out => numIn(i));
    end generate;

	regs: PROCESS (clk)   
	variable number_amount: integer;
	BEGIN
		IF clk'event and clk = '1' THEN
			IF regsRst = '1' THEN
				FOR i in 0 to NUM_MEMORY - 1 LOOP
					reg(i) <= 0;
				END LOOP;
				number_amount := 0;
			ELSIF didEnter = '1' THEN 
					FOR i in 1 to NUM_MEMORY - 1 LOOP
						reg(NUM_MEMORY - i) <= reg(NUM_MEMORY - i - 1);
					END LOOP;
					reg(0) <= to_integer(unsigned(numIn));
					IF number_amount < 4 THEN
						number_amount := number_amount + 1;
					END IF;
			ELSIF opAq = '1' THEN
				IF number_amount > 1 THEN 
					reg(0) <= calcResult;
					FOR i in 1 to NUM_MEMORY - 2 LOOP
						reg(i) <= reg(i + 1);
					END LOOP;
					reg(NUM_MEMORY - 1) <= 0;
					number_amount := number_amount - 1;
				END IF;
			END IF;
		END IF;
	END PROCESS;

	opManager: PROCESS (clk)
	VARIABLE opCounter: integer;
	VARIABLE commandWasAcquired: std_logic;
	BEGIN
		IF clk'event and clk = '1' THEN
			IF opIn /= "111" and opIn /= "000" THEN
				IF commandWasAcquired = '1' THEN
					regsRst <= '0';
					didEnter <= '0';
					opAq <= '0';
				ELSE
					IF opCounter < opCounterMax THEN 
						opCounter := opCounter + 1;
					ELSE
						opCounter := 0;
						CASE (opIn) IS 
							WHEN "110" => 	regsRst <= '1'; -- reset
											didEnter <= '0';
											opAq <= '0';
											commandWasAcquired := '1';

							WHEN "100" => 	regsRst <= '0'; -- enter
											didEnter <= '1';
											opAq <= '0';
											commandWasAcquired := '1';

							WHEN "000" => 	regsRst <= '0'; 
											didEnter <= '0';
											opAq <= '0';
											commandWasAcquired := '0';

							WHEN "111" => 	regsRst <= '0'; 
											didEnter <= '0';
											opAq <= '0';
											commandWasAcquired := '0';

							WHEN others => 	regsRst <= '0'; -- outros
											didEnter <= '0';
											opAq <= '1';
											commandWasAcquired := '1';
						END CASE;
					END IF;
				END IF;
			ELSE 
				opCounter := 0;
				regsRst <= '0';
				didEnter <= '0';
				opAq <= '0';
				commandWasAcquired := '0';
			END IF;
		END IF;

	END PROCESS;

	-- Calc block

	calcResult <= 	reg(0) + reg(1) WHEN opIn = "001" ELSE
					reg(1) - reg(0) WHEN opIn = "010" ELSE
					to_integer(to_unsigned(reg(1) * reg(0), N_BITS_NUM)) WHEN opIn = "011" ELSE 
					reg(1) / reg(0) WHEN opIn = "011" and reg(0) /= 0 ELSE
					0;

    -- falta enviar rpn_stack(0) para resultado e mostrar nos displays. ------
    resultado <= std_logic_vector(to_unsigned(reg(0), NUMDISPLAYS*7)); -- Add
    
    SSD_driver: for i in 1 to NUMDISPLAYS generate
    hex(i-1) <= resultado(4*i-1 downto 4*(i-1));
    ssd_saida(7*i-1 downto 7*(i-1)) <= 	  "1000000" WHEN hex(i-1) = "0000" ELSE
                                            "1111001" WHEN hex(i-1) = "0001" ELSE
                                            "0100100" WHEN hex(i-1) = "0010" ELSE
                                            "0110000" WHEN hex(i-1) = "0011" ELSE
                                            "0011001" WHEN hex(i-1) = "0100" ELSE
                                            "0010010" WHEN hex(i-1) = "0101" ELSE
                                            "0000010" WHEN hex(i-1) = "0110" ELSE
                                            "1111000" WHEN hex(i-1) = "0111" ELSE
                                            "0000000" WHEN hex(i-1) = "1000" ELSE
                                            "0010000" WHEN hex(i-1) = "1001" ELSE
                                            "0001000" WHEN hex(i-1) = "1010" ELSE
                                            "0000011" WHEN hex(i-1) = "1011" ELSE
                                            "1000110" WHEN hex(i-1) = "1100" ELSE
                                            "0100001" WHEN hex(i-1) = "1101" ELSE
                                            "0000110" WHEN hex(i-1) = "1110" ELSE
                                            "0001110" WHEN hex(i-1) = "1111" ELSE
                                            "1100100";

end generate SSD_driver;

END ARCHITECTURE;
