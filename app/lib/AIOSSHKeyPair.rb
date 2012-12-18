require 'sshkey'
require 'socket'
require 'fileutils'

class AIOSSHKeyPair
  class PassphraseRequiredError < StandardError; end

  attr_accessor :private_key_path, :public_key_path
  attr_accessor :public_key

  def generate!
    ssh_path = File.join Dir.home, '.ssh'
    private_key_path = File.join ssh_path, 'id_rsa'
    public_key_path = File.join ssh_path, 'id_rsa.pub'

    unless File.exists? private_key_path
      keypair = SSHKey.generate type: 'RSA', bits: 2048, comment: comment_fragment

      FileUtils.mkdir_p ssh_path
      File.open private_key_path, 'w' do |f|
        f.write keypair.private_key
      end
      FileUtils.chmod 0600, private_key_path

      File.open public_key_path, 'w' do |f|
        f.write keypair.ssh_public_key
      end
      FileUtils.chmod 0600, public_key_path

      self.private_key_path = private_key_path
      self.public_key_path = public_key_path
      self.public_key = keypair.ssh_public_key
    end
  end

  def find_keys
    ssh_path = File.join Dir.home, '.ssh'
    if Dir.exists? ssh_path
      %w(id_dsa id_rsa).each do |private_key_filename|
        private_key_path = File.join ssh_path, private_key_filename
        public_key_path = private_key_path + '.pub'

        if File.exists?(private_key_path)
          self.private_key_path = private_key_path
          self.public_key_path = File.exists?(public_key_path) ? public_key_path : nil
          return
        end
      end
    end
    self.public_key_path = nil
    self.private_key_path = nil
  end

  def read_public_key(passphrase='')
    find_keys
    if @public_key_path
      public_key = File.read @public_key_path
      if SSHKey.valid_ssh_public_key? public_key
        return self.public_key = public_key
      end
    elsif @private_key_path
      private_key_data = File.read @private_key_path
      if private_key_encrypted?(private_key_data) && (passphrase.nil? || passphrase == '')
        raise PassphraseRequiredError
      end
      keypair = SSHKey.new private_key_data, passphrase: passphrase, comment: comment_fragment

      public_key_path = @private_key_path + '.pub'
      File.open public_key_path, 'w' do |f|
        f.write keypair.ssh_public_key
      end
      FileUtils.chmod 0600, public_key_path

      self.public_key_path = public_key_path
      return self.public_key = keypair.ssh_public_key
    end
    self.public_key = nil
  end

  def public_key_md5_fingerprint
    return unless @public_key
    if key_fragment = @public_key[/\A\s*ssh-(rsa|dss)\s+([a-zA-Z0-9\+\/=]+)/, 2]
      Digest::MD5.hexdigest(Base64.decode64 key_fragment).gsub(/(.{2})(?=.)/, '\1:\2')
    end
  end

  def can_generate_keys
    @private_key_path.nil?
  end

  private
  def private_key_encrypted?(private_key)
    private_key.match(/^Proc-Type:.*ENCRYPTED.*$/) != nil
  end

  def comment_fragment
    "#{Etc.getlogin}@#{Socket.gethostname}"
  end
end

# Cocoa-specific
class AIOSSHKeyPair
  dependent_property :public_key_md5_fingerprint, [:public_key]
  dependent_property :can_generate_keys,          [:private_key_path]
end if RUBY_ENGINE == 'macruby'
