library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TrafficLightFSM is
    Port (
        clk : in  STD_LOGIC;  -- 100 MHz system clock
        reset : in  STD_LOGIC;  -- Master reset
                
        pedN : in  STD_LOGIC;  -- North pedestrian button
        pedS : in  STD_LOGIC;  -- South pedestrian button
        pedW : in  STD_LOGIC;  -- West pedestrian button
        pedE : in  STD_LOGIC;  -- East pedestrian button
        
        straightLightR: out STD_LOGIC; --Red light; The straight lights are for the first Tri-color LED. Applies to NS_SN and WE_EW for their respective states.
        straightLightG: out STD_LOGIC; -- Green Light; Combined with red to make the yellow light.
        straightLightB: out STD_LOGIC; --Blue light which is not used.
        
        turningLightR: out STD_LOGIC; --Red light; The turning lights are for the second tri-color LED. Applues to NE_SW and NW_SE for their respective states.
        turningLightG: out STD_LOGIC; --Green Light; COmbined with red to make the yellow light
        turningLightB: out STD_LOGIC; --Blue light which is not used
        
        pedNSStopLight: out STD_LOGIC; --Stop Light for pedestrians in NS crosswalk
        pedNSWalkLight: out STD_LOGIC; --Walk Light for pedestrians in NS crosswalk
        pedNSRunLight: out STD_LOGIC; --Run Light for pedestrians in NS crosswalk
        
        pedWEStopLight: out STD_LOGIC; --Stop Light for pedestrians in WE crosswalk
        pedWEWalkLight: out STD_LOGIC; --Walk Light for pedestrians in WE crosswalk
        pedWERunLight: out STD_LOGIC; --Run Light for pedestrians in WE crosswalk     
        
        seg: out STD_LOGIC_VECTOR(6 downto 0); --Seven Segments in each display
        an: out STD_LOGIC_VECTOR(7 downto 0)); --Anodes for the displays
        
        --stateOut : out STD_LOGIC_VECTOR(2 downto 0);  -- Output state (for debugging)
end TrafficLightFSM;

architecture Behavioral of TrafficLightFSM is
    component ClockDivider is
        Port (
            clkIn   : in  STD_LOGIC;
            reset   : in  STD_LOGIC;
            clkOut  : out STD_LOGIC
        );
    end component;
    
    component BinaryToBCD is
        generic( n: integer := 6; --n = number of bits
                digits: integer := 2); --digits is the number of BCD digits
        Port (
            binary : in STD_LOGIC_VECTOR (n - 1 downto 0); -- n bits
            bcd : out STD_LOGIC_VECTOR (4 * digits - 1 downto 0) -- # of bcd digits
        );
    end component;
    
    component SevenSegmentDriver is
        Port (
            clk : in STD_LOGIC; -- Clock signal for multiplexing
            bcd : in STD_LOGIC_VECTOR (7 downto 0); -- 2 BCD digits (8 bits)
            pedTimeCounter: in INTEGER; --pedestrianTimeCounter
            seg : out STD_LOGIC_VECTOR (6 downto 0); -- 7-segment output
            an : out STD_LOGIC_VECTOR (7 downto 0) -- Anode control
        ); 
    end component;

    -- Define FSM states
    type state_type is (emergency_state, NS_SN, NW_SE, WE_EW, NE_SW);
    signal currentState :state_type := emergency_state; --First state is emergency state
    signal nextState : state_type;

    -- Signals
    signal slowClk : STD_LOGIC := '0'; -- Internal slow clock (1 Hz or 1 s)
    signal timeCounter : INTEGER := 1; --Timers for traffic lights and crosswalks
    signal pedTimeCounter: INTEGER := 0; --Pedestrian Crosswalk Timer
    signal pedNSReq, pedWEReq: STD_LOGIC := '0'; --Holds the request if some has pressed the button to cross
    signal pedTimeCounterBinary: STD_LOGIC_VECTOR(5 downto 0); --Holds the vector, or 6 bit bus, of pedTimeCounter
    signal bcd: STD_LOGIC_VECTOR(7 downto 0); --Holds the bcd of pedTimeCounterVector to be displayed
    
    begin
    clkDiv: ClockDivider 
    port map(
        clkIn => clk,
        reset => reset,
        clkOut => slowClk
        );
        
    BINTOBCD: BinaryToBCD
    port map(
        binary => pedTimeCounterBinary,
        bcd => bcd
    );
       
    SSegmentDriver: SevenSegmentDriver
    port map(
        clk => clk,
        bcd => bcd,
        pedTimeCounter => pedTimeCounter,
        seg => seg,
        an => an
    );
    
    -- State Transition and timeCounter Update (1 ms)
    process (slowClk, reset, pedTimeCounter)
    begin
        if reset = '1' then
            currentState <= emergency_state; -- Default state on reset
            timeCounter  <= 1; --Resets timeCounter
            pedTimeCounter <= 0; --Resets pedTimeCounter
        elsif rising_edge(slowClk) then
            if timeCounter = 1 then
                currentState <= nextState;  -- Move to the next state
                case nextState is 
                    when NS_SN =>
                        timeCounter <= 100; -- 100 seconds (100 counts of 1 s) 90s of Green, 5 s of yellow, 5s of red
                    when NW_SE =>
                        timeCounter <= 25; -- 25 seconds (100 counts of 1 s) 15s of Green, 5 s of yellow, 5s of red
                    when WE_EW =>
                        timeCounter <= 100; -- 100 seconds (100 counts of 1 s) 90s of Green, 5 s of yellow, 5s of red
                    when NE_SW =>
                        timeCounter <= 25; -- 25 seconds (25 counts of 1 s) 15s of Green, 5 s of yellow, 5s of red
                    when others =>
                        timeCounter <= 1; -- Default to 1 for emergency
                end case;
            elsif timeCounter > 1 then
                timeCounter <= timeCounter - 1; -- Decrease counter only if > 1
            end if;
           
            if pedTimeCounter = 0 then
                if (currentState = NS_SN and timeCounter = 51) or (currentState = WE_EW and timeCounter = 51) then --51 seconds so pedestrians can cross before the light turns yellow
                    pedTimeCounter <= 40; -- 40 seconds in total to cross; 30 seconds to walk and 10s to run
                    if pedTimeCounter = 40 then
                            pedTimeCounterBinary <= STD_LOGIC_VECTOR(to_unsigned(pedTimeCounter, 6)); --Converts pedTimeCounter from integer to unsigned, and stores it in a vector to be converted to bcd and displayed
                    end if;
                end if;
            elsif pedTimeCounter > 0 then
                pedTimeCounter <= pedTimeCounter - 1;
                pedTimeCounterBinary <= STD_LOGIC_VECTOR(to_unsigned(pedTimeCounter, 6)); --Converts pedTimeCounter from integer to unsigned, and stores it in a vector to be converted to bcd and displayed
            end if;            
        end if;
    end process;

    -- FSM Transition Logic
    process (currentState, reset, timeCounter, pedN, pedS, pedW, pedE, pedTimeCounter, pedNSReq, pedWEReq)
    begin
        --All red lights are turned on, and the others are off by defualt
        straightLightR <= '1';
        straightLightG <= '0'; 
        straightLightB <= '0'; --This blue LED will not be turned on in this process since they are not needed.
        
        turningLightR <= '1';
        turningLightG <= '0';
        turningLightB <= '0'; --This blue LED will not be turned on in this process since they are not needed.
        
        pedNSStopLight <= '1';
        pedNSWalkLight <= '0';
        pedNSRunLight <= '0';
        
        pedWEStopLight <= '1';
        pedWEWalkLight <= '0';
        pedWERunLight <= '0';
    
        case currentState is
            when emergency_state =>
                if reset = '1' then
                    straightLightG <= '0'; --Light assignments
                    straightLightR <= '1'; --Red Light is on
                    
                    turningLightG <= '0';
                    turningLightR <= '1'; --Red Light is on
                    
                    pedNSStopLight <= '1'; --NS Stop Light is on
                    pedNSWalkLight <= '0';
                    pedNSRunLight <= '0';
                    
                    pedWEStopLight <= '1'; --WE Stop Light is on
                    pedWEWalkLight <= '0';
                    pedWERunLight <= '0';
                    
                    pedNSReq <= '0';
                    pedWEReq<= '0';
                     
                    nextState <= emergency_state;  -- Stay in emergency mode
                else
                    nextState <= NS_SN;  -- Exit emergency mode when emergency is over
                end if;
    
            when NS_SN =>
                if timeCounter > 10 then --Green Light
                    straightLightG <= '1'; --Green Light On
                    straightLightR <= '0'; --Red Light Off
                    turningLightR <= '1'; --Turning Red Light on
                elsif timeCounter > 5 then --Yellow Light
                    straightLightG <= '1'; --Green Light on
                    straightLightR <= '1'; -- Red Light on with Green Light on to make Yellow Light
                    turningLightR <= '1'; --Turning Red Light on
                    pedWEReq <= '0';
                else --Red Light
                    straightLightG <= '0'; --Green light off 
                    straightLightR <= '1'; --Red Light on
                    turningLightR <= '1'; --Turning Red Light on
                end if;
                
                if pedN = '1' or pedS = '1' then
                    pedNSReq <= '1';
                end if;
                
                if pedNSReq = '1' and timeCounter < 52 then --If it is time to cross and the request was made
                    if pedTimeCounter > 10 then  --If it is the first 30 seconds of crossing, then display walking
                        pedNSStopLight <= '0';
                        pedNSWalkLight <= '1';
                        pedNSRunLight <= '0';
                    else --Display run
                        pedNSStopLight <= '0';
                        pedNSWalkLight <= '0';
                        pedNSRunLight <= '1';
                    end if;
                else
                    pedNSStopLight <= '1';
                    pedNSWalkLight <= '0';
                    pedNSRunLight <= '0';
                end if;
                
                if pedW = '1' or pedE = '1' then
                    pedWEReq <= '1';
                end if;
                
                pedWEStopLight <= '1'; --WE Stop Light is on
                pedWEWalkLight <= '0';
                pedWERunLight <= '0';
                
                nextState <= NW_SE;

            when NW_SE =>
                if timeCounter > 10 then --Green Light
                    turningLightG <= '1'; --Green Light On
                    turningLightR <= '0'; --Red Light Off
                    straightLightR <= '1'; --Straight Red Light off
                elsif timeCounter > 5 then --Yellow Light
                    turningLightG <= '1'; --Green Light on
                    turningLightR <= '1'; -- Red Light on with Green Light on to make Yellow Light
                    straightLightR <= '1'; --Straight Red Light off
                else --Red Light
                    turningLightG <= '0'; --Green light off
                    turningLightR <= '1'; --Red Light on
                    straightLightR <= '1'; --Straight Red Light off
                end if;
                
                if pedN = '1' or pedS = '1' then
                    pedNSReq <= '1';
                end if;
                
                if pedW = '1' or pedE = '1' then
                    pedWEReq <= '1';
                end if;

                pedNSStopLight <= '1'; --NS Stop Light is on
                pedNSWalkLight <= '0';
                pedNSRunLight <= '0';
                
                pedWEStopLight <= '1'; --WE Stop Light is on
                pedWEWalkLight <= '0';
                pedWERunLight <= '0';
                            
                nextState <= WE_EW; 

            when WE_EW =>
                if timeCounter > 10 then --Green Light
                    straightLightG <= '1'; --Green Light On
                    straightLightR <= '0'; --Red Light Off
                    turningLightR <= '1'; --Turning Red Light on
                elsif timeCounter > 5 then --Yellow Light
                    straightLightG <= '1'; --Green Light on
                    straightLightR <= '1'; -- Red Light on with Green Light on to make Yellow Light
                    turningLightR <= '1'; --Turning Red Light on
                    pedWEReq <= '0';
                else --Red Light
                    straightLightG <= '0'; --Green light off 
                    straightLightR <= '1'; --Red Light on
                    turningLightR <= '1'; --Turning Red Light on
                end if;
                
                if pedW = '1' or pedE = '1' then
                    pedWEReq <= '1';
                end if;   
                
                if pedWEReq = '1' and timeCounter < 52 then --If it is time to cross and the request was made
                    if pedTimeCounter > 10 then --If it is the first 30 seconds of crossing, then display walking
                        pedWEStopLight <= '0';
                        pedWEWalkLight <= '1';
                        pedWERunLight <= '0';
                    else --Display run
                        pedWEStopLight <= '0';
                        pedWEWalkLight <= '0';
                        pedWERunLight <= '1';
                    end if;
                else
                    pedWEStopLight <= '1';
                    pedWEWalkLight <= '0';
                    pedWERunLight <= '0';
                end if; 
                
                if pedN = '1' or pedS = '1' then
                    pedNSReq <= '1';
                end if;
                
                pedNSStopLight <= '1'; --NS Stop Light is on
                pedNSWalkLight <= '0';
                pedNSRunLight <= '0';
                     
                nextState <= NE_SW;

            when NE_SW =>
                if timeCounter > 10 then --Green Light
                    turningLightG <= '1'; --Green Light On
                    turningLightR <= '0'; --Red Light Off
                    straightLightR <= '1'; --Straight Red Light off
                elsif timeCounter > 5 then --Yellow Light
                    turningLightG <= '1'; --Green Light on
                    turningLightR <= '1'; -- Red Light on with Green Light on to make Yellow Light
                    straightLightR <= '1'; --Straight Red Light off
                else --Red Light
                    turningLightG <= '0'; --Green light off
                    turningLightR <= '1'; --Red Light on
                    straightLightR <= '1'; --Straight Red Light off
                end if;
                
                if pedN = '1' or pedS = '1' then
                    pedNSReq <= '1';
                end if;
                
                if pedW = '1' or pedE = '1' then
                    pedWEReq <= '1';
                end if;

                
                pedNSStopLight <= '1'; --NS Stop Light is on
                pedNSWalkLight <= '0';
                pedNSRunLight <= '0';
                
                pedWEStopLight <= '1'; --WE Stop Light is on
                pedWEWalkLight <= '0';
                pedWERunLight <= '0';
            
                nextState <= NS_SN; -- Loop back
               
            when others =>
                straightLightG <= '0';
                straightLightR <= '1';
                
                turningLightG <= '0';
                turningLightR <= '1';
                
                pedNSStopLight <= '1'; --NS Stop Light is on
                pedNSWalkLight <= '0';
                pedNSRunLight <= '0';
                
                pedWEStopLight <= '1'; --WE Stop Light is on
                pedWEWalkLight <= '0';
                pedWERunLight <= '0';
                
                nextState <= emergency_state;
        end case;
    end process;

    -- Output state for debugging
    --process (currentState)
    --begin
        --case currentState is
            --when emergency_state => stateOut <= "000";
            --when NS_SN => stateOut <= "001";
            --when NW_SE => stateOut <= "010";
            --when WE_EW => stateOut <= "011";
            --when NE_SW => stateOut <= "100";
            --when others => stateOut <= "000"; -- Default to emergency
        --end case;
    --end process;    
end Behavioral;
