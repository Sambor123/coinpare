# frozen_string_literal: true

require 'pastel'
require 'tty-spinner'
require 'tty-table'

require_relative '../command'
require_relative '../fetcher'

module Coinpare
  module Commands
    class Markets < Coinpare::Command
      def initialize(name, options)
        @name = name
        @options = options
        @pastel = Pastel.new
        @spinner = TTY::Spinner.new(':spinner Fetching data...',
                                    format: :dots, clear: true)
      end

      def execute(input: $stdin, output: $stdout)
        @spinner.auto_spin

        to_symbol = fetch_symbol
        response = Fetcher.fetch_top_exchanges_by_pair(
                     @name.upcase, @options['base'].upcase, @options)

        table = setup_table(response["Data"]["Exchanges"], to_symbol)

        @spinner.stop

        output.puts banner
        output.puts table.render(:unicode, padding: [0, 1], alignment: :right)
      ensure
        @spinner.stop
      end

      def fetch_symbol
        prices = Fetcher.fetch_prices(
                   @name.upcase, @options['base'].upcase, @options)
        prices['DISPLAY'][@name.upcase][@options['base'].upcase]['TOSYMBOL']
      end

      def banner
        "\n#{add_color('Coin', :yellow)} #{@name.upcase}  " \
        "#{add_color('Base Currency', :yellow)} #{@options['base'].upcase}  " \
        "#{add_color('Time', :yellow)} #{timestamp}\n\n"
      end

      def setup_table(data, to_symbol)
        table = TTY::Table.new(header: [
          { value: 'Market', alignment: :left },
          'Price',
          'Chg. 24H',
          'Chg.% 24H',
          'Open 24H',
          'High 24H',
          'Low 24H',
          'Direct Vol. 24H',
        ])

        data.each do |market|
          change24h = market['CHANGE24HOUR']
          market_details = [
            { value: add_color(market['MARKET'], :yellow), alignment: :left },
            add_color("#{to_symbol} #{number_to_currency(round_to(market['PRICE']))}", pick_color(change24h)),
            add_color("#{pick_arrow(change24h)} #{to_symbol} #{number_to_currency(round_to(change24h))}", pick_color(change24h)),
            add_color("#{pick_arrow(change24h)} #{round_to(market['CHANGEPCT24HOUR'] * 100)}%", pick_color(change24h)),
            "#{to_symbol} #{number_to_currency(round_to(market['OPEN24HOUR']))}",
            "#{to_symbol} #{number_to_currency(round_to(market['HIGH24HOUR']))}",
            "#{to_symbol} #{number_to_currency(round_to(market['LOW24HOUR']))}",
            "#{to_symbol} #{number_to_currency(round_to(market['VOLUME24HOURTO']))}"
          ]
          table << market_details
        end

        table
      end
    end # Markets
  end # Commands
end # Coinpare