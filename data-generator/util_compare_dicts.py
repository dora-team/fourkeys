def flatten(d, sep="_"):
    obj = {}

    def recurse(t, parent_key=""):

        if isinstance(t, list):
            for i in range(len(t)):
                recurse(t[i], parent_key + sep + str(i) if parent_key else str(i))
        elif isinstance(t, dict):
            for k, v in t.items():
                recurse(v, parent_key + sep + k if parent_key else k)
        else:
            obj[parent_key] = t

    recurse(d)

    return obj


def compare_dicts(dict_a, dict_b):

    errors = []

    # flatten any nested structures, so we only need one pass
    flat_dict_a = flatten(dict_a)
    flat_dict_b = flatten(dict_b)

    if flat_dict_a.keys() != flat_dict_b.keys():
        errors.append("dictionary keys do not match")

    for key in flat_dict_a:

        if not isinstance(flat_dict_a[key], type(flat_dict_b[key])):
            errors.append(
                f"type mismatch comparing '{key}': {type(flat_dict_a[key]).__name__} != {type(flat_dict_b[key]).__name__}"
            )
        elif isinstance(flat_dict_a[key], str) and len(flat_dict_a[key]) != len(
            flat_dict_b[key]
        ):
            errors.append(
                f"length mismatch comparing strings in '{key}': {len(flat_dict_a[key])} != {len(flat_dict_b[key])}"
            )

    if errors:
        return "\n".join(errors)

    return "pass"
