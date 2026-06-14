import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/exercise.dart';
import '../../services/workout_repository.dart';
import '../../providers/supabase_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../common/app_card.dart';

class CreateCustomExerciseDialog extends ConsumerStatefulWidget {
  final VoidCallback? onExerciseCreated;
  final Exercise? exercise; // For editing existing exercises

  const CreateCustomExerciseDialog({
    super.key, 
    this.onExerciseCreated,
    this.exercise,
  });

  @override
  ConsumerState<CreateCustomExerciseDialog> createState() => _CreateCustomExerciseDialogState();
}

class _CreateCustomExerciseDialogState extends ConsumerState<CreateCustomExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '12');
  final _weightController = TextEditingController(text: '20');
  final _restController = TextEditingController(text: '60');
  
  MuscleGroup _selectedMuscleGroup = MuscleGroup.chest;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill form if editing existing exercise
    if (widget.exercise != null) {
      final exercise = widget.exercise!;
      _nameController.text = exercise.name;
      _descriptionController.text = exercise.description ?? '';
      _setsController.text = exercise.sets.length.toString();
      _repsController.text = exercise.sets.first.targetReps.toString();
      _weightController.text = exercise.sets.first.targetWeight.toString();
      _restController.text = exercise.restSeconds.toString();
      _selectedMuscleGroup = exercise.muscleGroup;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _restController.dispose();
    super.dispose();
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final exercise = Exercise(
        id: widget.exercise?.id ?? 'custom-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        muscleGroup: _selectedMuscleGroup,
        description: _descriptionController.text.trim(),
        sets: List.generate(
          int.parse(_setsController.text),
          (i) => ExerciseSet(
            id: 'set-${widget.exercise?.id ?? DateTime.now().millisecondsSinceEpoch}-$i',
            setNumber: i + 1,
            targetReps: int.parse(_repsController.text),
            targetWeight: double.parse(_weightController.text),
          ),
        ),
        restSeconds: int.parse(_restController.text),
      );

      final repository = ref.read(workoutRepositoryProvider);
      
      if (widget.exercise == null) {
        // Create new exercise
        await repository.saveCustomExercise(exercise);
      } else {
        // Update existing exercise
        await repository.updateCustomExercise(exercise);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.exercise == null 
                ? 'Custom exercise created successfully!' 
                : 'Exercise updated successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
        // Call the callback to refresh the exercise list
        widget.onExerciseCreated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${widget.exercise == null ? 'create' : 'update'} exercise: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteExercise() async {
    if (widget.exercise == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text('Are you sure you want to delete "${widget.exercise!.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(workoutRepositoryProvider).deleteCustomExercise(widget.exercise!.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exercise deleted successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
        // Call the callback to refresh the exercise list
        widget.onExerciseCreated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete exercise: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    const Icon(Icons.fitness_center, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        widget.exercise == null ? 'Create Custom Exercise' : 'Edit Exercise',
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Form content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Exercise Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Exercise Name *',
                          hintText: 'e.g., My Custom Press',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an exercise name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Muscle Group
                      DropdownButtonFormField<MuscleGroup>(
                        value: _selectedMuscleGroup,
                        decoration: const InputDecoration(
                          labelText: 'Muscle Group *',
                        ),
                        items: MuscleGroup.values.map((group) {
                          return DropdownMenuItem(
                            value: group,
                            child: Text(group.label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedMuscleGroup = value);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'e.g., Keep elbows at 75° angle',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Settings row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _setsController,
                              decoration: const InputDecoration(
                                labelText: 'Sets *',
                                hintText: '3',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final sets = int.tryParse(value);
                                if (sets == null || sets < 1 || sets > 10) {
                                  return '1-10 sets';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: _repsController,
                              decoration: const InputDecoration(
                                labelText: 'Reps *',
                                hintText: '12',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final reps = int.tryParse(value);
                                if (reps == null || reps < 1 || reps > 100) {
                                  return '1-100 reps';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              decoration: const InputDecoration(
                                labelText: 'Weight (kg) *',
                                hintText: '20',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final weight = double.tryParse(value);
                                if (weight == null || weight < 0 || weight > 1000) {
                                  return '0-1000 kg';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: _restController,
                              decoration: const InputDecoration(
                                labelText: 'Rest (sec) *',
                                hintText: '60',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final rest = int.tryParse(value);
                                if (rest == null || rest < 0 || rest > 600) {
                                  return '0-600 sec';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveExercise,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(widget.exercise == null ? 'Create Exercise' : 'Save Changes'),
                          ),
                        ),
                      ],
                    ),
                    if (widget.exercise != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _deleteExercise,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Delete Exercise'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
