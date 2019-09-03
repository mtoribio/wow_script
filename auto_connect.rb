# frozen_string_literal: true

require 'pathname'
require 'open3'
require 'mini_magick'
require 'active_support/all'
require 'time_difference'
require 'auto_click'
class WowAuto
  include AutoClickMethods

  SRC_DIR = './img'
  TMP_DIR = './tmp'

  def initialize; end

  def open_blizzard
    mouse_move(280, 1069)
    sleep 5
    left_click
    sleep 5
  end

  def open_wow
    mouse_move(390, 985)
    sleep 5
    left_click
    sleep 5
  end

  def open_server
    mouse_move(645, 267)
    sleep 5
    left_click
    sleep 5

    mouse_move(1123, 855)
    sleep 5
    left_click
    sleep 5
  end

  # @return [void]
  def connect
    puts 'take screenshot'
    sleep 2
    `./screenCapture img/hola.jpg`
    puts 'Init Image recognition'
    Dir.mkdir TMP_DIR unless File.exist?(TMP_DIR)

    Pathname.new(SRC_DIR).children.each do |f|
      src_path = f.realpath
      tmp_path = "#{TMP_DIR}/#{f.basename}"

      img = MiniMagick::Image.open(src_path)
      img.colorspace('Gray')
      img.write(tmp_path)

      MiniMagick::Tool::Magick.new do |magick|
        magick << tmp_path
        magick.negate
        magick.threshold('30%')
        magick.negate
        magick << tmp_path
      end

      text, =
        Open3.capture3("tesseract #{tmp_path} stdout -l eng --oem 0 --psm 3")

      time_waiting_str = text.strip.split("\n")
                             .map { |k| k if k.include?('Tiempo de espera estimado:') }
                             .compact.first
      unless time_waiting_str
        sleep 5
        WowAuto.connect
      end
      wow_time = time_waiting_str
                 .split(':')
                 .last.to_i
      start_time = Time.parse('16:00')
      end_time = Time.parse('18:00')
      time_until18 = TimeDifference.between(start_time, end_time).in_minutes
      if time_until18.negative?
        end_time += 1.day
        time_until18 = TimeDifference.between(start_time, end_time).in_minutes
      end

      if (time_until18 - wow_time) < 25
        # connect
        puts 'Connecting...'
      else
        puts 'Sleeping...'
        sleep 10 * 60
        run
      end
    end
  end

  def run
    open_blizzard
    open_wow
    open_server
    connect
  end
end
WowAuto.new.run

# Mouse coords 390 985
