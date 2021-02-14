import collections

def flatten(d,sep="_"):
    obj = collections.OrderedDict()

    def recurse(t,parent_key=""):
        
        if isinstance(t,list):
            for i in range(len(t)):
                recurse(t[i],parent_key + sep + str(i) if parent_key else str(i))
        elif isinstance(t,dict):
            for k,v in t.items():
                recurse(v,parent_key + sep + k if parent_key else k)
        else:
            obj[parent_key] = t

    recurse(d)

    return obj


def compare_dicts(dict_a, dict_b):
    
    # flatten any nested structures, so we only need one pass
    flat_dict_a = collections.OrderedDict(flatten(dict_a))
    flat_dict_b = collections.OrderedDict(flatten(dict_b))

    print(flat_dict_b)
    print(flat_dict_a)

    assert flat_dict_a.keys() == flat_dict_b.keys(), \
        f"dictionary keys do not match: {list(flat_dict_a.keys())} != {list(flat_dict_b.keys())}"

    for key in flat_dict_a:

        assert type(flat_dict_a[key]) == type(flat_dict_b[key]), \
            f"type mismatch comparing '{key}': {type(flat_dict_a[key]).__name__} != {type(flat_dict_b[key]).__name__}"

        if isinstance(flat_dict_a[key], str):
            assert len(flat_dict_a[key]) == len(flat_dict_b[key]), \
                f"length mismatch comparing strings in '{key}': {len(flat_dict_a[key])} != {len(flat_dict_b[key])}"
