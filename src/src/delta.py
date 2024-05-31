from .delta_functions.bnn import delta_bnn
from .delta_functions.tnn import delta_tnn


class Delta_Manager:
    def __init__(self, s):
        self.s = s 
    def delta_calculation(self, l = None, v = None,debugging = False, u = None, move = None):
        if self.s.settings.network_type == "BNN":
            return delta_bnn(self.s, l, v).moves
        elif self.s.settings.network_type == "TNN":
            return delta_tnn(self.s, l, v).moves
        else:
            return ValueError(f"No delta evaluation implemented for {self.s.settings.network_type}")