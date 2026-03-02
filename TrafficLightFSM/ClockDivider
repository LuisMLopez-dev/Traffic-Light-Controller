library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ClockDivider is
    Port (
        clkIn   : in  STD_LOGIC;  -- 100 MHz system clock
        reset   : in  STD_LOGIC;  -- Reset signal
        clkOut  : out STD_LOGIC   -- 500ms clock output
    );
end ClockDivider;

architecture Behavioral of ClockDivider is
    signal count  : INTEGER := 0;
    signal clkReg : STD_LOGIC := '0';
    
    begin
    process (clkIn, reset)
    begin
        if reset = '1' then
            count  <= 0;
            clkReg <= '0';
        elsif rising_edge(clkIn) then
            if count = 100000000 - 1 then  -- Counts to 100 million (1 Hz or 1 s)
                count  <= 0;
                clkReg <= NOT clkReg;  -- Toggle clock output
            else
                count <= count + 1;
            end if;
        end if;
    end process;

    clkOut <= clkReg;  -- Assign output clock signal
end Behavioral;
