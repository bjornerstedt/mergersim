# Mergersim 2

Mergersim 2 is an update of the __mergersim__ package, [published in the Stata Journal](https://www.stata-journal.com/article.html?article=st0349), a Stata package for merger simulation with nested logit demand. It is currently a beta version, requiring some testing. For a description of new features, read the [update documentation](https://github.com/bjornerstedt/mergersim/blob/master/docs/mergersim2.pdf).

## Installation

To run the program:

- [Download the program](https://github.com/bjornerstedt/mergersim/archive/master.zip) to a folder of your choice.
- Run Stata in this folder.
- In Stata, the command `compile` is required to compile the Mata code before the first time the program is used. 
- Due to limitations in Stata in the naming of functions, Mergersim 2 cannot be run in the same session as the first version of the program. 
- Mergersim 2 has the same syntax as Mergersim 1, with extensions as described in the documentation.
- You can put the program in your personal ado path, as described in the Stata documentation. Do __not__ do this, however, if you have the first version of Mergersim installed.

If you find errors or have feature requests, I would greatly appreciate if you file them [here](https://github.com/bjornerstedt/mergersim/issues).
