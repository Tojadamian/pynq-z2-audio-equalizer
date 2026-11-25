library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.eq_coeffs_pkg.all;

entity fir_filter is
    generic (
        NUM_TAPS : integer := FILTER_TAPS;
        DATA_WIDTH : integer := 12;
        COEF_WIDTH : integer := 13;
        SUM_WIDTH : integer := 33;
        COEFFS : coeffs_array := COEF_LPF
        );
    port (
        clk : in std_logic;
        reset : in std_logic;
        en : in std_logic;
        din : in signed(DATA_WIDTH-1 downto 0);
        dout : out signed(SUM_WIDTH-1 downto 0)
    );
            
end entity fir_filter;

architecture structural of fir_filter is
    type data_pipe_t is array(0 to NUM_TAPS) of signed(DATA_WIDTH-1 downto 0);
    type sum_pipe_t is array(0 to NUM_TAPS) of signed(SUM_WIDTH-1 downto 0);
    signal data_pipe : data_pipe_t;
    signal sum_pipe : sum_pipe_t;
begin
    data_pipe(0) <= din;
    sum_pipe(0) <= (others => '0');
    gen_mac : for i in 0 to NUM_TAPS-1 generate
        mac_inst : entity work.mac_cell
            generic map (
                DATA_WIDTH => DATA_WIDTH,
                COEF_WIDTH => COEF_WIDTH,
                SUM_WIDTH => SUM_WIDTH
            )
            port map (
                clk => clk,
                reset => reset,
                en => en,
                in_coef => COEFFS(i),
                in_data => data_pipe(i),
                in_sum => sum_pipe(i),
                out_data => data_pipe(i+1),
                out_sum => sum_pipe(i+1)
            );
    end generate;
    dout <= sum_pipe(NUM_TAPS);
end architecture structural;
