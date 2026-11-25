library ieee;
use ieee.std_logic_1164.all;

entity top_audio_eq is
    port (
        clk   : in std_logic;
        reset : in std_logic;
        sw_audio : in std_logic;
        sw_eq : in std_logic;
        btn_lpf : in std_logic;
        btn_bpf : in std_logic;
        btn_hpf : in std_logic;
        adc_cs : out std_logic;
        spi_miso_adc : in std_logic;
        spi_sck_adc : out std_logic;
        led_audio : out std_logic;
        led_lpf : out std_logic;
        led_bpf : out std_logic;
        led_hpf : out std_logic;
        dac_cs : out std_logic;
        spi_mosi_dac_A : out std_logic;
        spi_sck_dac : out std_logic
    );
end entity;

architecture structural of top_audio_eq is
    signal en_adc : std_logic;
    signal en_dsp : std_logic;
    signal en_dac : std_logic;
    signal led_blink : std_logic;

    signal en_lpf : std_logic;
    signal en_bpf : std_logic;
    signal en_hpf : std_logic;

    signal adc_sample : std_logic_vector(11 downto 0) := (others => '0');
    signal eq_sample : std_logic_vector(11 downto 0) := (others => '0');
    signal audio_selected : std_logic_vector(11 downto 0) := (others => '0');
    signal dac_sample : std_logic_vector(11 downto 0) := (others => '0');

begin
    u_timing : entity work.timing_gen
        port map (
            clk => clk,
            reset => reset,
            en_adc => en_adc,
            en_dsp => en_dsp,
            en_dac => en_dac,
            led_blink => led_blink
        );
    u_btn_lpf : entity work.btn_controller
        port map (
            clk => clk,
            reset => reset,
            btn_in => btn_lpf,
            state_out => en_lpf
        );
    u_btn_bpf : entity work.btn_controller
        port map (
            clk => clk,
            reset => reset,
            btn_in => btn_bpf,
            state_out => en_bpf
        );
    u_btn_hpf : entity work.btn_controller
        port map (
            clk => clk,
            reset => reset,
            btn_in => btn_hpf,
            state_out => en_hpf
        );
    u_adc : entity work.adc_controller
        port map (
            clk => clk,
            reset => reset,
            en => en_adc,
            sdata => spi_miso_adc,
            sclk => spi_sck_adc,
            cs => adc_cs,
            adc_data_out => adc_sample
        );
    u_eq : entity work.audio_equalizer
        port map (
            clk => clk,
            reset => reset,
            en => en_dsp,
            en_lpf => en_lpf,
            en_bpf => en_bpf,
            en_hpf => en_hpf,
            din => adc_sample,
            dout => eq_sample
        );
    
    u_dac : entity work.dac_controller
        port map (
            clk => clk,
            reset => reset,
            en => en_dac,
            dac_data_in => dac_sample,
            sclk => spi_sck_dac,
            sync => dac_cs,
            din => spi_mosi_dac_A
        );
    audio_selected <= eq_sample when sw_eq = '1' else adc_sample;

    dac_sample <= audio_selected when sw_audio =  '1' else X"800";
    
    led_audio <= '0' when sw_audio = '0' else led_blink 
        when sw_eq = '1' else '1';

    led_lpf <= en_lpf when (sw_audio = '1' and sw_eq = '1') else '0';
    led_bpf <= en_bpf when (sw_audio = '1' and sw_eq = '1') else '0';
    led_hpf <= en_hpf when (sw_audio = '1' and sw_eq = '1') else '0';   

end architecture structural;