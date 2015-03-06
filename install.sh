chmod 755 cwc15
mkdir -p /usr/local/bin/
rm -r /usr/local/bin/cwc15
ln -s $PWD/cwc15 /usr/local/bin/
gem install json
echo "cwc15 installed!"
