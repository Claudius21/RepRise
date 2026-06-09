import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/exercise.dart';
import '../../models/workout_plan.dart';
import '../../providers/workout_provider.dart';
import '../../screens/workout/workout_tracking_screen.dart';
import '../../services/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_card.dart';

class PlanEditScreen extends ConsumerStatefulWidget {
  final WorkoutPlan plan;

  const PlanEditScreen({super.key, required this.plan});

  @override
  ConsumerState<PlanEditScreen> createState() => _PlanEditScreenState();
}

class _PlanEditScreenState extends ConsumerState<PlanEditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late WorkoutPlan _plan;

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
    _tabController = TabController(length: _plan.days.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _saveAndPop() {
    ref.read(workoutPlansProvider.notifier).updatePlan(_plan);
    Navigator.pop(context);
  }

  void _updateDay(WorkoutDay updated) {
    setState(() {
      _plan = _plan.copyWith(
        days: _plan.days.map((d) => d.id == updated.id ? updated : d).toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Edit: ${_plan.name}',
            style: Theme.of(context).textTheme.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveAndPop,
            child: const Text(
              'Save',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.background,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.onSurfaceMuted,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14),
              tabs: _plan.days.map((d) => Tab(text: d.name)).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _plan.days
            .map((day) => _DayEditView(
                  day: day,
                  onDayChanged: _updateDay,
                ))
            .toList(),
      ),
    );
  }
}

class _DayEditView extends StatefulWidget {
  final WorkoutDay day;
  final void Function(WorkoutDay) onDayChanged;

  const _DayEditView({required this.day, required this.onDayChanged});

  @override
  State<_DayEditView> createState() => _DayEditViewState();
}

class _DayEditViewState extends State<_DayEditView>
    with AutomaticKeepAliveClientMixin {
  late List<Exercise> _exercises;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _exercises = List.of(widget.day.exercises);
  }

  void _notify() {
    widget.onDayChanged(widget.day.copyWith(exercises: _exercises));
  }

  void _removeExercise(String id) {
    setState(() => _exercises.removeWhere((e) => e.id == id));
    _notify();
  }

  void _reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, item);
    });
    _notify();
  }

  void _updateExerciseSets(String exerciseId, List<ExerciseSet> sets) {
    setState(() {
      _exercises = _exercises.map((e) {
        if (e.id != exerciseId) return e;
        return e.copyWith(sets: sets);
      }).toList();
    });
    _notify();
  }

  void _addExercise(Exercise exercise) {
    if (_exercises.any((e) => e.id == exercise.id)) return;
    setState(() => _exercises.add(exercise));
    _notify();
  }

  void _showAddExercise() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ExercisePickerSheet(
        onAdd: _addExercise,
        alreadyAdded: _exercises.map((e) => e.id).toSet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            itemCount: _exercises.length,
            onReorder: _reorder,
            buildDefaultDragHandles: false,
            itemBuilder: (ctx, i) {
              final ex = _exercises[i];
              return ReorderableDragStartListener(
                key: ValueKey(ex.id),
                index: i,
                child: _EditableExerciseCard(
                  exercise: ex,
                  onRemove: () => _removeExercise(ex.id),
                  onSetsChanged: (sets) => _updateExerciseSets(ex.id, sets),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: OutlinedButton.icon(
            onPressed: _showAddExercise,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Add Exercise'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditableExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final VoidCallback onRemove;
  final void Function(List<ExerciseSet>) onSetsChanged;

  const _EditableExerciseCard({
    super.key,
    required this.exercise,
    required this.onRemove,
    required this.onSetsChanged,
  });

  @override
  State<_EditableExerciseCard> createState() => _EditableExerciseCardState();
}

class _EditableExerciseCardState extends State<_EditableExerciseCard> {
  late List<ExerciseSet> _sets;

  @override
  void initState() {
    super.initState();
    _sets = List.of(widget.exercise.sets);
  }

  void _addSet() {
    final last = _sets.lastOrNull;
    final newSet = ExerciseSet(
      id: 'set-edit-${DateTime.now().millisecondsSinceEpoch}-${_sets.length}',
      setNumber: _sets.length + 1,
      targetReps: last?.targetReps ?? 10,
      targetWeight: last?.targetWeight ?? 0,
    );
    setState(() => _sets.add(newSet));
    widget.onSetsChanged(_sets);
  }

  void _removeSet(String setId) {
    if (_sets.length <= 1) return;
    setState(() {
      _sets.removeWhere((s) => s.id == setId);
      for (var i = 0; i < _sets.length; i++) {
        _sets[i] = _sets[i].copyWith(setNumber: i + 1);
      }
    });
    widget.onSetsChanged(_sets);
  }

  void _editSet(ExerciseSet set, {bool isReps = true}) {
    final controller = TextEditingController(
      text: isReps
          ? set.targetReps.toString()
          : set.targetWeight.toStringAsFixed(1),
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(isReps ? 'Edit Reps' : 'Edit Weight (kg)'),
        content: TextField(
          controller: controller,
          keyboardType: isReps
              ? TextInputType.number
              : const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            hintText: isReps ? 'Reps' : 'kg',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = controller.text.trim();
              setState(() {
                _sets = _sets.map((s) {
                  if (s.id != set.id) return s;
                  if (isReps) {
                    return s.copyWith(targetReps: int.tryParse(val) ?? s.targetReps);
                  } else {
                    return s.copyWith(targetWeight: double.tryParse(val) ?? s.targetWeight);
                  }
                }).toList();
              });
              widget.onSetsChanged(_sets);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmRemove() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Remove Exercise?'),
        content: Text('"${widget.exercise.name}" will be removed from this day.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onRemove();
            },
            child: const Text('Remove',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.drag_handle_rounded,
                    color: AppColors.onSurfaceMuted, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fitness_center,
                      size: 14, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.exercise.name,
                          style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        '${widget.exercise.muscleGroup.label} · ${widget.exercise.restSeconds}s rest',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _confirmRemove,
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 20, color: AppColors.error),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Header row
            Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                    child: Text('Set',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall)),
                Expanded(
                    child: Text('Reps',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall)),
                Expanded(
                    child: Text('Weight',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall)),
              ],
            ),
            const SizedBox(height: 4),
            ..._sets.map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Set ${s.setNumber}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _editSet(s, isReps: true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: AppRadius.smRadius,
                            ),
                            child: Text(
                              '${s.targetReps}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _editSet(s, isReps: false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: AppRadius.smRadius,
                            ),
                            child: Text(
                              s.targetWeight > 0
                                  ? '${s.targetWeight.toStringAsFixed(1)} kg'
                                  : 'BW',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        child: _sets.length > 1
                            ? GestureDetector(
                                onTap: () => _removeSet(s.id),
                                child: const Icon(Icons.remove_circle_outline,
                                    size: 20, color: AppColors.error),
                              )
                            : const SizedBox(),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: AppSpacing.xs),
            TextButton.icon(
              onPressed: _addSet,
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text('Add Set'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
