import cactvsenv

from pycactvs import Ens

from pycactvs import Ens

for s in ['O=[N+](O)c1ccco1', 'C1=C(OC(=C1)[N+]([O-])=O)CNCC2COCCC2', 'c1ccoc1', 'C=Cc1ccco1', 'O=C(O)c1ccco1']:
    e = Ens(s)
    p = e.get('E_FICUS_STRUCTURE')
    print(p.get('E_SMILES'))


