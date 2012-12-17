require 'SpecHelper'
require 'AIOSSHKeyPair'
require 'fileutils'
require 'sshkey'

describe AIOSSHKeyPair do
  before do
    FakeFS.activate!
    @keypair = AIOSSHKeyPair.new
  end

  after do
    FakeFS.deactivate!
    FakeFS::FileSystem.clear
  end

  describe '#generate!' do
    before do
      @ssh_path = File.join Dir.home, '.ssh'
    end

    context 'when id_rsa file exists' do
      before do
        FileUtils.mkdir_p @ssh_path
        FileUtils.touch File.join(@ssh_path, 'id_rsa')
        @keypair.generate!
      end

      it 'does not do anything' do
        @keypair.private_key_path.should.be.nil
        @keypair.public_key_path.should.be.nil
        @keypair.public_key.should.be.nil
      end
    end

    context 'when id_rsa file does not exist' do
      it 'generates and saves an ssh key pair' do
        SSHKey.should.receive(:generate) do |options|
          options[:type].should.equal 'RSA'
          options[:bits].should.equal 2048
          options[:comment].should.equal @keypair.send(:comment_fragment)
          mock 'keypair', private_key: 'some-private-key', ssh_public_key: 'some-public-key'
        end

        private_key_path = File.join @ssh_path, 'id_rsa'
        public_key_path = File.join @ssh_path, 'id_rsa.pub'

        @keypair.should.receive(:private_key_path=).with private_key_path
        @keypair.should.receive(:public_key_path=).with public_key_path
        @keypair.should.receive(:public_key=).with 'some-public-key'

        @keypair.generate!

        File.read(private_key_path).should.equal 'some-private-key'
        File.read(public_key_path).should.equal 'some-public-key'
      end
    end
  end

  describe '#find_keys' do
    context 'when ~/.ssh directory does not exist' do
      it 'sets @public_key_path and @private_key_path to be nil' do
        @keypair.should.receive(:private_key_path=).with nil
        @keypair.should.receive(:public_key_path=).with nil
        @keypair.find_keys
      end
    end

    context 'when ~/.ssh directory exists' do
      before do
        @ssh_path = File.join(Dir.home, '.ssh')
        FileUtils.mkdir_p @ssh_path
      end

      context 'when no keys exist' do
        it 'sets @public_key_path and @private_key_path to be nil' do
          @keypair.should.receive(:private_key_path=).with nil
          @keypair.should.receive(:public_key_path=).with nil
          @keypair.find_keys
        end
      end

      context 'when id_rsa and id_rsa.pub files exist' do
        before do
          FileUtils.touch File.join(@ssh_path, 'id_rsa')
          FileUtils.touch File.join(@ssh_path, 'id_rsa.pub')
        end

        it 'sets @public_key_path and @private_key_path accordingly' do
          @keypair.should.receive(:private_key_path=).with File.join(@ssh_path, 'id_rsa')
          @keypair.should.receive(:public_key_path=).with File.join(@ssh_path, 'id_rsa.pub')
          @keypair.find_keys
        end
      end

      context 'when id_dsa and id_dsa.pub files exist' do
        before do
          FileUtils.touch File.join(@ssh_path, 'id_dsa')
          FileUtils.touch File.join(@ssh_path, 'id_dsa.pub')
        end

        it 'sets @public_key_path and @private_key_path accordingly' do
          @keypair.should.receive(:private_key_path=).with File.join(@ssh_path, 'id_dsa')
          @keypair.should.receive(:public_key_path=).with File.join(@ssh_path, 'id_dsa.pub')
          @keypair.find_keys
        end
      end

      context 'when only id_rsa file exists' do
        before do
          FileUtils.touch File.join(@ssh_path, 'id_rsa')
        end

        it 'sets @private_key_path accordingly and sets @public_key_path to be nil' do
          @keypair.should.receive(:private_key_path=).with File.join(@ssh_path, 'id_rsa')
          @keypair.should.receive(:public_key_path=).with nil
          @keypair.find_keys
        end
      end

      context 'when only id_dsa file exists' do
        before do
          FileUtils.touch File.join(@ssh_path, 'id_dsa')
        end

        it 'sets @private_key_path accordingly and sets @public_key_path to be nil' do
          @keypair.should.receive(:private_key_path=).with File.join(@ssh_path, 'id_dsa')
          @keypair.should.receive(:public_key_path=).with nil
          @keypair.find_keys
        end
      end
    end
  end

  describe '#read_public_key' do
    before do
      @ssh_path = File.join(Dir.home, '.ssh')
      FileUtils.mkdir_p @ssh_path
    end

    context 'when public key exists' do
      context 'when public key is invalid' do
        before do
          FileUtils.touch File.join(@ssh_path, 'id_rsa')
          File.open(File.join(@ssh_path, 'id_rsa.pub'), 'w') { |f| f.write 'invalid private key' }
        end

        it 'returns nil' do
          @keypair.should.receive(:public_key=).with nil
          @keypair.read_public_key.should.be.nil
        end
      end

      context 'when public key is valid' do
        before do
          @public_key = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAYQDHCDhLX+JlcAyoIPRAbUhRQtcb/Gkr4J6dj5VEthj//UT9KeTgSgZTgtHSKswz0jQT0Xp4VmRTkIbbSp8DspQ/CxG7C7UDkIg2DiX/Pr7SavrohGCROhBu3YVj6JXtq/E= foo@bar'
          FileUtils.touch File.join(@ssh_path, 'id_rsa')
          File.open(File.join(@ssh_path, 'id_rsa.pub'), 'w') { |f| f.write @public_key }
        end

        it 'reads public key from file' do
          @keypair.should.receive(:public_key=).with @public_key
          @keypair.read_public_key.should.equal @public_key
        end
      end
    end

    context 'when public key does not exist' do
      context 'when private key exists' do
        context 'when key is not encrypted' do
          before do
            @private_key = "-----BEGIN RSA PRIVATE KEY-----\nMIIBygIBAAJhAMcIOEtf4mVwDKgg9EBtSFFC1xv8aSvgnp2PlUS2GP/9RP0p5OBK\nBlOC0dIqzDPSNBPRenhWZFOQhttKnwOylD8LEbsLtQOQiDYOJf8+vtJq+uiEYJE6\nEG7dhWPole2r8QIDAQABAmBYXOXhUOiKcHyuCDNohxwcN7iYzC9FM6w3948lulLP\nE/qVCwx6J2M3oFTXIfkW6LM9nB7goCxksuByDSkbCwYydVVnAzTZ/5myfTQxc0VF\nSiub0RIkPQid104K4ELgfCECMQDrkmlldnCUKoQe/Sw7YXuKtlgrzLH/oQY8QTO0\nzIqRN2CFzowRkUbHdhRH59cslkMCMQDYSqQkaOHljhYeg7CCvMdbwI9b7ZwQEs9Q\nPw51LRg8R4PPEO4Ar+yug5APjyjAY7sCMQDmfFg2981qira+g0NVzilMLODT6fF2\nhZxONBVdHoutTZtZECAnyBaSbcumFwaHD3UCMBaJqJL2rttJs/pYBJOK8kcYSJfu\nqX1vSFT3TR1eppDZbt2ryPEfY81HfkJwy3FIswIwdff7ry5sIJym7MavnQUJcaWS\nM656hDvl+o0rO3Nlo/LOvWwwMw2wJHJkyN//bfwM\n-----END RSA PRIVATE KEY-----\n"
            @public_key = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAYQDHCDhLX+JlcAyoIPRAbUhRQtcb/Gkr4J6dj5VEthj//UT9KeTgSgZTgtHSKswz0jQT0Xp4VmRTkIbbSp8DspQ/CxG7C7UDkIg2DiX/Pr7SavrohGCROhBu3YVj6JXtq/E= '
            @public_key << @keypair.send(:comment_fragment)
            File.open(File.join(@ssh_path, 'id_rsa'), 'w') { |f| f.write @private_key }
          end

          it 'extracts public key from private key' do
            @keypair.should.receive(:public_key=).with @public_key
            @keypair.read_public_key.should.equal @public_key
          end
        end

        context 'when private key is encrypted' do
          before do
            @private_key = "-----BEGIN RSA PRIVATE KEY-----\nProc-Type: 4,ENCRYPTED\nDEK-Info: AES-128-CBC,5D4CF4310892CAC62BE957F23B5B5C49\n\n2lPCSXDPsPB7tSUvNf58tP+CICreGs4RrCCW/1Je/2DeP5sL1cPCjFhlIWP79IdT\nnbe177ymnUq59stQrhlqEmErMi3Qpt3TSollW0vYD9QStmW4OPMFFZn7SLdY5smo\nc0L4hjuxTKsbdz0EzoAcuv+ezVC2Ko3HMGkhsJ+KEUJQ4aQwmpCCql/1hfORkpO+\nogr74CtgZGWg151tTsyKxntOrAvPV50utGLs1uOjv5eVEH/GHE/bkMZ6xV5pq/Ns\nCi8Zc4C7uGQKoQWMRkR+OwwROn09pRanXx1tQ1u7odfJvWN3uAO+lbhxKHRIr7yt\nzdNktsmSRUnruvwwr28jUlBwQJDQ5XV0ZNl+g0yXcXYfUqncR50czcLOUv8dT0Fg\n9DNmFNSkEOw6LQ4cV7xS2KeelQ8vjSjcorzpyS07FQ4SWy2m5Le3HQ709kt+d5nb\nk6/nqwtLzSNX8rb3quK8so91HvaavYiDQSEyJtBsBiAAvms3SBt3EFm3jVAuR3C0\nhQA6CvGTdJYictMO8DFhBxeDqistMAkQz5Gdb826upL1bHXakWWr+R2qiaGA9jXM\nBgyLhTE+3xXtb7MZyMvsVyLjhaVpBevfJnqEAU/0R3I=\n-----END RSA PRIVATE KEY-----\n"
            @public_key = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAYQC7Fr2fsGIgOthrAEeLocgVkoKBIvPWdups7+9CvKJDSbc5yf95drqx+FAOqNC4F7yAF0QQrEAiJ+zACyXlOkg5GZnsXIqrnTZPRBl622i2gj32L0pV+qHPw0MP5P1pxWE= '
            @public_key << @keypair.send(:comment_fragment)
            File.open(File.join(@ssh_path, 'id_rsa'), 'w') { |f| f.write @private_key }
          end

          context 'when passphrase is correct' do
            it 'extracts public key form private key' do
              @keypair.should.receive(:public_key=).with @public_key
              @keypair.read_public_key('foobarbaz').should.equal @public_key
            end
          end

          context 'when passphrase is not given' do
            it 'raises an exception' do
              -> {
                @keypair.read_public_key
              }.should.raise AIOSSHKeyPair::PassphraseRequiredError
            end
          end

          context 'when passphrase is incorrect' do
            it 'raises an exception' do
              -> {
                @keypair.read_public_key 'abcd'
              }.should.raise Exception
            end
          end
        end
      end

      context 'when private key also does not exist' do
        it 'returns nil' do
          @keypair.should.receive(:public_key=).with nil
          @keypair.read_public_key.should.be.nil
        end
      end
    end
  end
end
