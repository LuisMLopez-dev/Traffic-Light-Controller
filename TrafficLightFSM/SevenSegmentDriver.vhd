library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SevenSegmentDriver is
    Port (
        clk : in STD_LOGIC; -- Clock signal for multiplexing
        bcd : in STD_LOGIC_VECTOR (7 downto 0); -- 2 BCD digits (8 bits)
        pedTimeCounter: in INTEGER; --pedestrian Time Counter
        seg : out STD_LOGIC_VECTOR (6 downto 0); -- 7-segment output
        an : out STD_LOGIC_VECTOR (7 downto 0)); -- Anode control
end SevenSegmentDriver;

architecture Behavioral of SevenSegmentDriver is
    signal digit : STD_LOGIC_VECTOR (3 downto 0);
    signal displaySelect : INTEGER range 0 to 5 := 0;
    signal counter : INTEGER := 0;
    
    begin
    process(clk) -- Clock divider
    begin
        if rising_edge(clk) then
            if counter = 6250 then --16 kHz total frequency for the 8 displays, 2 kHz for each display
                counter <= 0;
                displaySelect <= (displaySelect + 1) mod 6; -- Cycle through the first 6 displays
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    -- Multiplexing logic
    process(displaySelect, bcd, pedTimeCounter)
    begin
        if pedTimeCounter = 0 then
            digit <= "1111";
            an <= "11111111";
        else
            case displaySelect is
                when 0 =>
                    digit <= bcd(3 downto 0); -- Least significant digit
                    an <= "11111110"; -- Activates first display
                when 1 =>
                    digit <= bcd(7 downto 4);
                    an <= "11111101"; -- Activates second display
                when others =>
                    digit <= "1111"; -- Default
                    an <= "11111111"; -- Turns off all displays
            end case;
        end if;
    end process;

    decoder: entity work.SevenSegmentDecoder
    port map (
        digit => digit,
        segments => seg
    );
end Behavioral;
