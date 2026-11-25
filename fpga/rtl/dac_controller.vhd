
library ieee;
use ieee.std_logic_1164.all;

entity dac_controller is
    generic (
        HALF_DIV : integer := 30 -- 125 MHz / (2 * 30) = 2.083 MHz SCLK
    );
    port (
        clk   : in std_logic;
        reset : in std_logic;
        en : in std_logic;
        dac_data_in : in std_logic_vector(11 downto 0);
        sclk : out std_logic;
        sync : out std_logic;
        din : out std_logic
        -- Data input to DAC
    );
end entity;

architecture rtl of dac_controller is
    type state_type is (IDLE, SCLK_HIGH, SCLK_LOW);
    signal state : state_type := IDLE;

    signal half_cnt : integer range 0 to HALF_DIV - 1 := 0;
    signal bit_cnt : integer range 0 to 15 := 0;
    signal shift_reg : std_logic_vector(15 downto 0) := (others => '0');

    signal sclk_reg : std_logic := '1';
    signal sync_reg : std_logic := '1';
begin
    process(clk)
    begin 
        if rising_edge(clk) then
            if reset = '1' then
                state <= IDLE;
                half_cnt <= 0;
                bit_cnt <= 0;
                shift_reg <= (others => '0');
                sclk_reg <= '1';
                sync_reg <= '1';
            else
                case state is
                    when IDLE =>
                        sync_reg <= '1';
                        sclk_reg <= '1';
                        half_cnt <= 0;
                        bit_cnt <= 0;
                        if en = '1' then
                          shift_reg <= "0000" & dac_data_in;
                          sync_reg <= '0'; -- Assert sync to start DAC transaction
                          state <= SCLK_HIGH;
                        end if;
                    when SCLK_HIGH =>
                        if half_cnt = HALF_DIV - 1 then
                            half_cnt <= 0;
                            sclk_reg <= '0';
                            state <= SCLK_LOW;
                        else
                            half_cnt <= half_cnt + 1;
                        end if;
                    when SCLK_LOW =>
                        if half_cnt = HALF_DIV - 1 then
                            half_cnt <= 0;
                            sclk_reg <= '1';
                            if bit_cnt = 15 then
                                bit_cnt <= 0;
                                sync_reg <= '1'; -- Deassert sync to end DAC transaction
                                state <= IDLE;
                            else
                                shift_reg <= shift_reg(14 downto 0) & '0';
                                bit_cnt <= bit_cnt + 1;
                                state <= SCLK_HIGH;
                            end if;
                        else
                            half_cnt <= half_cnt + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;

    sclk <= sclk_reg;
    sync <= sync_reg;
    din <= shift_reg(15) when state /= IDLE else '0';
end architecture rtl;
