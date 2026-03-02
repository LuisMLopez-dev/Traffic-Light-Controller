library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity BinaryToBCD is
    generic( n: integer := 6; --n = number of bits
            digits: integer := 2); --digits is the number of BCD digits
    Port (
        binary : in STD_LOGIC_VECTOR (n - 1 downto 0); -- n bits
        bcd : out STD_LOGIC_VECTOR (4 * digits - 1 downto 0) -- # of bcd digits
    );
end BinaryToBCD;

architecture Behavioral of BinaryToBCD is
    begin
    process(binary)
        variable temp : UNSIGNED(n - 1 downto 0);
        variable bcdTemp : UNSIGNED(4 * digits - 1 downto 0) := (others => '0');
    begin
        temp := UNSIGNED(binary); -- Convert input to UNSIGNED
        bcdTemp := (others => '0');

        -- Double Dabble algorithm
        for i in 0 to n - 1 loop
            -- Add 3 if any BCD digit is greater than 4 before shifting
            for j in 0 to digits - 1 loop
                if bcdTemp((j+1)*4-1 downto j*4) > "0100" then
                    bcdTemp((j+1)*4-1 downto j*4) := bcdTemp((j+1)*4-1 downto j*4) + 3;
                end if;
            end loop;

            -- Shift left: Move temp into bcdTemp
            bcdTemp := bcdTemp(4 * digits - 2 downto 0) & temp(n - 1);
            temp := temp(n - 2 downto 0) & '0';
        end loop;

        bcd <= STD_LOGIC_VECTOR(bcdTemp); -- Convert output back to STD_LOGIC_VECTOR
    end process;
end Behavioral;
