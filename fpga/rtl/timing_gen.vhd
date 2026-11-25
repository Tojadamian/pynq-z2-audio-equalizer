library ieee;
use ieee.std_logic_1164.all;

entity timing_gen is
    generic (
    DIV_24KHZ : integer := 5208;
    BLINK_HALF_PERIOD : integer := 31_250_000
    );

    port (
        clk   : in std_logic;
        reset : in std_logic;
        en_adc : out std_logic;
        en_dsp : out std_logic;
        en_dac : out std_logic;
        led_blink : out std_logic
    );
end entity;

architecture rtl of timing_gen is
    signal cnt_24khz : integer range 0 to DIV_24KHZ - 1 := 0;
    signal cnt_blink : integer range 0 to BLINK_HALF_PERIOD - 1 := 0;
    signal blink_reg : std_logic := '0';

begin
process(clk)
begin
    if rising_edge(clk) then
        if reset = '1' then
            cnt_24khz <= 0;
            cnt_blink <= 0;
            blink_reg <= '0';
            en_adc <= '0';
            en_dsp <= '0';
            en_dac <= '0';
        else
            en_adc <= '0';
            en_dsp <= '0';
            en_dac <= '0';       
            if cnt_24khz = 0 then
                en_adc <= '1';
            elsif cnt_24khz = DIV_24KHZ / 2 then
            en_dsp <= '1';
            elsif cnt_24khz = (DIV_24KHZ / 2) + 4 then
            en_dac <= '1';
            end if;
        if cnt_24khz = DIV_24KHZ - 1 then 
            cnt_24khz <= 0;
        else 
        cnt_24khz <= cnt_24khz + 1;
        end if;
        if cnt_blink = BLINK_HALF_PERIOD - 1 then
        cnt_blink <= 0;
        blink_reg <= not blink_reg;
        else 
        cnt_blink <= cnt_blink + 1;
        end if;
        end if; -- end of else for reset
    end if;
end process;
led_blink <= blink_reg;
end architecture;