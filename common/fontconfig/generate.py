#!/usr/bin/env python

import sys
from string import Template

fontconfig_template = """
<?xml version='1.0'?>
<!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
<fontconfig>
  <alias>
    <family>serif</family>
    <prefer>
      <family>$serif</family>
    </prefer>
  </alias>
  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>$sans_serif</family>
    </prefer>
  </alias>
  <alias>
    <family>sans</family>
    <prefer>
      <family>$sans_serif</family>
    </prefer>
  </alias>
  <alias>
    <family>monospace</family>
    <prefer>
      <family>$monospace</family>
    </prefer>
  </alias>
  <!-- Aliases for commonly used MS fonts. -->
  <match>
    <test name="family">
      <string>Arial</string>
    </test>
    <edit name="family" mode="assign" binding="strong">
      <string>$sans_serif</string>
    </edit>
  </match>
  <match>
    <test name="family">
      <string>Helvetica</string>
    </test>
    <edit name="family" mode="assign" binding="strong">
      <string>$sans_serif</string>
    </edit>
  </match>
  <match>
    <test name="family">
      <string>Verdana</string>
    </test>
    <edit name="family" mode="assign" binding="strong">
      <string>$sans_serif</string>
    </edit>
  </match>
  <match>
    <test name="family">
      <string>Tahoma</string>
    </test>
    <edit name="family" mode="assign" binding="strong">
      <string>$sans_serif</string>
    </edit>
  </match>
  <match>
    <!-- Insert joke here -->
    <test name="family">
      <string>Comic Sans MS</string>
    </test>
    <edit name="family" mode="assign" binding="strong">
      <string>$sans_serif</string>
    </edit>
  </match>
  <match>
    <test name="family">
      <string>Times New Roman</string>
    </test>
    <edit name="family" mode="assign" binding="strong">
      <string>$serif</string>
    </edit>
  </match>
  <match>
    <test name="family">
      <string>Times</string>
    </test>
    <edit name="family" mode="assign" binding="strong">
      <string>$serif</string>
    </edit>
  </match>
  <match>
    <test name="family">
      <string>Courier New</string>
    </test>
    <edit name="family" mode="assign" binding="strong">
      <string>$monospace</string>
    </edit>
  </match>
</fontconfig>
"""

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: generate.py $serif $sans_serif $monospace")
        print("e.g. generate.py Tinos Arimo Cousine")
        sys.exit(1)
    serif = sys.argv[1]
    sans_serif = sys.argv[2]
    monospace = sys.argv[3]
    print(Template(fontconfig_template).substitute(serif=serif, sans_serif=sans_serif, monospace=monospace).strip())
