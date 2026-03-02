library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity SevenSegmentDecoder is
    Port (
        digit : in STD_LOGIC_VECTOR (3 downto 0); -- 4-bit BCD input (0-9)
        segments : out STD_LOGIC_VECTOR (6 downto 0) 
    );
end SevenSegmentDecoder;

architecture Behavioral of SevenSegmentDecoder is
    begin
    process(digit)
    begin
        case digit is --Based on digit, the segments will turn on accordingly (active-low)
            when "0000" => segments <= "1000000"; -- 0
            when "0001" => segments <= "1111001"; -- 1
            when "0010" => segments <= "0100100"; -- 2
            when "0011" => segments <= "0110000"; -- 3
            when "0100" => segments <= "0011001"; -- 4
            when "0101" => segments <= "0010010"; -- 5
            when "0110" => segments <= "0000010"; -- 6
            when "0111" => segments <= "1111000"; -- 7
            when "1000" => segments <= "0000000"; -- 8
            when "1001" => segments <= "0010000"; -- 9
            when others => segments <= "1111111"; -- Nothing is displayed
        end case;
    end process;
end Behavioral;
