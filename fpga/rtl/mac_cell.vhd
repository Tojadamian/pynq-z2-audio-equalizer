library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mac_cell is
    generic (
        DATA_WIDTH : integer := 12;
        COEF_WIDTH : integer := 13;
        SUM_WIDTH : integer := 33
    );
    port (
        clk : in std_logic;
        reset : in std_logic;
        en : in std_logic;
        in_coef : in integer;
        in_data : in signed(DATA_WIDTH-1 downto 0);
        in_sum : in signed(SUM_WIDTH-1 downto 0);
        out_data : out signed(DATA_WIDTH-1 downto 0);
        out_sum : out signed(SUM_WIDTH-1 downto 0)
    );

end entity mac_cell;

architecture rtl of mac_cell is

    signal data_d1 : signed(DATA_WIDTH-1 downto 0) := (others => '0');
    signal data_d2 : signed(DATA_WIDTH-1 downto 0) := (others => '0');
    signal sum_reg : signed(SUM_WIDTH-1 downto 0) := (others => '0');
begin
    process(clk)
        variable prod_v : signed(DATA_WIDTH + COEF_WIDTH - 1 downto 0);
    begin
        if rising_edge(clk) then
            if reset = '1' then
                data_d1 <= (others => '0');
                data_d2 <= (others => '0');
                sum_reg <= (others => '0');
            elsif en = '1' then
                data_d1 <= in_data;
                data_d2 <= data_d1;
                prod_v := in_data * to_signed(in_coef, COEF_WIDTH);
                sum_reg <= in_sum + resize(prod_v, SUM_WIDTH);
            end if;
        end if;
    end process;

out_data <= data_d2;
out_sum <= sum_reg;

end architecture rtl;