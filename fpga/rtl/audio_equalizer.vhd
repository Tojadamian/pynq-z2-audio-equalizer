library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.eq_coeffs_pkg.all;

entity audio_equalizer is
    port (
        clk : in std_logic;
        reset : in std_logic;
        en : in std_logic;
        en_lpf : in std_logic;
        en_bpf : in std_logic;
        en_hpf : in std_logic;
        din : in std_logic_vector(11 downto 0);
        dout : out std_logic_vector(11 downto 0)
    );
end entity audio_equalizer;

architecture rtl of audio_equalizer is
    constant DATA_WIDTH : integer := 12;
    constant COEF_WIDTH : integer := 13;
    constant SUM_WIDTH : integer := 33;
    constant MIX_WIDTH : integer := 35;

    signal din_signed : signed(DATA_WIDTH-1 downto 0);
    signal lpf : signed(SUM_WIDTH-1 downto 0);
    signal bpf : signed(SUM_WIDTH-1 downto 0);
    signal hpf : signed(SUM_WIDTH-1 downto 0);

begin
    din_signed <= signed((not din(11)) & din(10 downto 0));
    fir_lpf_inst : entity work.fir_filter
        generic map (
            NUM_TAPS => FILTER_TAPS,
            DATA_WIDTH => DATA_WIDTH,
            COEF_WIDTH => COEF_WIDTH,
            SUM_WIDTH => SUM_WIDTH,
            COEFFS => COEF_LPF
        )
        port map (
            clk => clk,
            reset => reset,
            en => en,
            din => din_signed,
            dout => lpf
        );
    fir_bpf_inst : entity work.fir_filter
        generic map (
            NUM_TAPS => FILTER_TAPS,
            DATA_WIDTH => DATA_WIDTH,
            COEF_WIDTH => COEF_WIDTH,
            SUM_WIDTH => SUM_WIDTH,
            COEFFS => COEF_BPF
        )
        port map (
            clk => clk,
            reset => reset,
            en => en,
            din => din_signed,
            dout => bpf
        );
    fir_hpf_inst : entity work.fir_filter
        generic map (
            NUM_TAPS => FILTER_TAPS,
            DATA_WIDTH => DATA_WIDTH,
            COEF_WIDTH => COEF_WIDTH,
            SUM_WIDTH => SUM_WIDTH,
            COEFFS => COEF_HPF
        )
        port map (
            clk => clk,
            reset => reset,
            en => en,
            din => din_signed,
            dout => hpf
        );
process(clk)
    variable total_v : signed(MIX_WIDTH-1 downto 0);
    variable scaled_v : signed(MIX_WIDTH-1 downto 0);
    variable sat_v : signed(DATA_WIDTH-1 downto 0);
begin
    if rising_edge(clk) then
        if reset = '1' then
            dout <= X"800";
        else
            total_v := (others => '0');
            if en_lpf = '1' then
                total_v := total_v + resize(lpf, MIX_WIDTH);
            end if;
            if en_bpf = '1' then
                total_v := total_v + resize(bpf, MIX_WIDTH);
            end if;
            if en_hpf = '1' then
                total_v := total_v + resize(hpf, MIX_WIDTH);
            end if;

            scaled_v := shift_right(total_v, EQ_SCALE_BITS);

            if scaled_v > to_signed(2**(DATA_WIDTH-1)-1, MIX_WIDTH) then
                sat_v := to_signed(2**(DATA_WIDTH-1)-1, DATA_WIDTH);
            elsif scaled_v < to_signed(-(2**(DATA_WIDTH-1)), MIX_WIDTH) then
                sat_v := to_signed(-(2**(DATA_WIDTH-1)), DATA_WIDTH);
            else
                sat_v := resize(scaled_v, DATA_WIDTH);
            end if;

            dout <= (not sat_v(11)) & std_logic_vector(sat_v(10 downto 0));
        end if;
    end if;
end process;
end architecture rtl;