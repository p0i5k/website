require "rubygems/package"

class Soc < ApplicationRecord
  COMMAND_BLOCKS = %w[backup bootloader firmware restore].freeze

  belongs_to :vendor
  has_many :custom_commands
  accepts_nested_attributes_for :custom_commands

  before_validation :generate_urlname
  validates :model, presence: true, uniqueness: { scope: :vendor_id }
  validates :urlname, presence: true, uniqueness: true

  RELEASES_ROOT = "/srv/github-releases"
  GH_DL_ROOT = "https://github.com/OpenIPC/firmware/releases/download/latest/%s"

  STATUS = {
    "neq": "No equipment on hands",
    "rnd": "Research and development",
    "hlp": "Looking for help",
    "wip": "Work in progress",
    "mvp": "Minimum viable product",
    "done": "Done and done!"
  }.freeze

  def self.find(id)
    find_by_urlname(id) || find_by_id(id)
  end

  def model_downcase
    @model_downcase ||= model.downcase
  end

  def to_param
    urlname
  end

  def bl_url
    format GH_DL_ROOT, uboot_filename
  end

  def fw_url(version)
    filename = linux_filename.dup
    filename.gsub("-br.tgz", "-#{version}-br.tgz") unless version.eql?("lite")
    format GH_DL_ROOT, filename
  end

  def tc_url
    format GH_DL_ROOT, toolchain_filename
  end

  def full_name
    [vendor.name, model].join(" ")
  end

  def instructable?
    !uboot_filename.empty? && !linux_filename.empty?
  end

  def kernel_file
    @kernel_file ||= "uImage.#{model_downcase}"
  end

  def linux_file(release)
    linux_filename.gsub!('-br.tgz', "-#{release}-br.tgz") unless release.eql?("lite")
    @linux_file ||= File.join(RELEASES_ROOT, linux_filename)
  end

  def rootfs_file
    @rootfs_file ||= "rootfs.squashfs.#{model_downcase}"
  end

  def uboot_file
    @uboot_file ||= File.join(RELEASES_ROOT, uboot_filename)
  end

  def full_firmware_path
    @full_firmware_path ||= "/tmp/openipc.#{model_downcase}.8mb.bin"
  end

  private

    def generate_urlname
      self.urlname = model.downcase.gsub(' ', '-')
    end
end
