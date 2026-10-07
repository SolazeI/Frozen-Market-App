import 'package:flutter/material.dart';

import '../core/utils/validators.dart';
import '../models/psgc_location.dart';
import 'frost_text_field.dart';
import 'location_picker.dart';

/// PSGC location pickers + street address. Shared by Register, Edit Profile
/// and Edit Shop so address UI lives in one place.
class AddressFields extends StatelessWidget {
  const AddressFields({
    super.key,
    required this.address,
    required this.location,
    required this.onLocationChanged,
    this.addressLabel = 'Street / house no.',
  });

  final TextEditingController address;
  final PsgcLocation location;
  final ValueChanged<PsgcLocation> onLocationChanged;
  final String addressLabel;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          LocationPicker(value: location, onChanged: onLocationChanged),
          const SizedBox(height: 14),
          FrostTextField(
            label: addressLabel,
            controller: address,
            validator: Validators.address,
          ),
        ],
      );
}
