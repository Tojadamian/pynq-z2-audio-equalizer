library ieee;
use ieee.std_logic_1164.all;

entity adc_controller is
    generic (
        HALF_DIV : integer := 30 -- 125 MHz / (2 * 30) = 2.083 MHz SCLK
    );
    port (
        clk   : in std_logic;
        reset : in std_logic;
        en : in std_logic;
        sdata : in std_logic;
        sclk : out std_logic;
        cs : out std_logic;
        adc_data_out : out std_logic_vector(11 downto 0)
    );
end entity;

architecture rtl of adc_controller is
    type state_type is (IDLE, SCLK_HIGH, SCLK_LOW);
    signal state : state_type := IDLE;
    signal half_cnt : integer range 0 to HALF_DIV-1 := 0;
    signal bit_cnt : integer range 0 to 15 := 0;
    signal shift_reg : std_logic_vector(15 downto 0) := (others => '0'); -- Sample MISO right before falling SCLK edge
    signal data_reg : std_logic_vector(11 downto 0) := X"800";
    signal sclk_reg : std_logic := '1';
    signal cs_reg : std_logic := '1';
    signal sdata_meta : std_logic :='0';  -- 2-stage MISO synchronization
    signal sdata_sync : std_logic :='0';  -- synchronized MISO signal
begin
    process(clk) is
    begin
        if rising_edge(clk) then 
            if reset = '1' then
                shift_reg <= (others => '0');
                half_cnt <= 0;
                bit_cnt <= 0;
                sdata_meta <= '0';
                sdata_sync <= '0';
                data_reg <= X"800";
                sclk_reg <= '1';
                cs_reg <= '1';
                state <= IDLE;
            else 
                sdata_meta <= sdata;
                sdata_sync <= sdata_meta;
                case state is
                    when IDLE =>
                        cs_reg <= '1';
                        sclk_reg <= '1';
                        half_cnt <= 0;
                        bit_cnt <= 0;
                        if en = '1' then
                            cs_reg <= '0';
                            state <= SCLK_HIGH;
                        end if;
                    when SCLK_HIGH =>
                        if half_cnt = HALF_DIV - 1 then
                            half_cnt <= 0;
                            shift_reg <= shift_reg(14 downto 0) & sdata_sync;
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
                                cs_reg <= '1';
                                data_reg <= shift_reg(11 downto 0);
                                state <= IDLE;
                            else
                                bit_cnt <= bit_cnt + 1;
                                state <= SCLK_HIGH;
                            end if;
                        else
                            half_cnt <= half_cnt + 1;
                        end if;
                end case;
            end if; -- if reset = '1'
        end if; -- rising_edge(clk)
    end process;

    sclk <= sclk_reg;
    cs <= cs_reg;
    adc_data_out <= data_reg;
end architecture;