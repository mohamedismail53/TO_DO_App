import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import 'package:todo_app/modules/Archived_Tasks/ArchivedTasksScreen.dart';
import 'package:todo_app/modules/Done_Tasks/DoneTasksScreen.dart';
import 'package:todo_app/modules/New_Tasks/NewTasksScreen.dart';
import 'package:todo_app/shared/cubit/states.dart';

class AppCubit extends Cubit<AppStates> {
  AppCubit() : super(AppInitState());

  static AppCubit get(context) => BlocProvider.of(context);

  int currentIndex = 0;

  List<String> titles = [
    'New Tasks',
    'Done Tasks',
    'Archived Tasks',
  ];

  List<Widget> screens = [
    NewTasksScreen(),
    DoneTasksScreen(),
    ArchivedTasksScreen(),
  ];

  void chageIndex(int index) {
    currentIndex = index;
    emit(AppChangeButtomNavBar());
  }

  Database db;
  List<Map> newTasks = [];
  List<Map> doneTasks = [];
  List<Map> archivedTasks = [];

  void createDatabase() {
    openDatabase(
      'todo.db',
      version: 1,
      onCreate: (db, version) {
        // print('database is created');
        db
            .execute(
                'CREATE TABLE tasks (id INTEGER PRIMARY KEY, title TEXT, data TEXT, time TEXT, status TEXT)')
            .then((value) {
          // print('table is created');
        }).catchError((error) {
          print('error is ${error.toString()}');
        });
      },
      onOpen: (db) {
        getDataFromDatabase(db);
        // print('database is opened');
      },
    ).then((value) {
      db = value;
      emit(AppCreateDatabaseState());
    });
  }

  insertToDatabase({
    @required String title,
    @required String time,
    @required String date,
  }) async {
    await db.transaction((txn) {
      txn
          .rawInsert(
              'INSERT INTO tasks(title, data, time, status) VALUES("$title", "$date", "$time", "New")')
          .then((value) {
        // print('$value inserted successfully');
        emit(AppInsertToDatabaseState());

        getDataFromDatabase(db);
      }).catchError((onError) {
        print('error when inserting new record');
      });
      return null;
    });
  }

  void getDataFromDatabase(db) {
    newTasks = [];
    doneTasks = [];
    archivedTasks = [];
    emit(AppGetDatabaseLoadingState());
    db.rawQuery('SELECT * FROM tasks').then((value) {
      value.forEach((element) {
        if (element['status'] == 'New')
          newTasks.add(element);
        else if (element['status'] == 'done')
          doneTasks.add(element);
        else
          archivedTasks.add(element);
      });
      emit(AppGetDatabaseState());
    });
  }

  void updataData({
    @required String status,
    @required int id,
  }) async {
    db.rawUpdate('UPDATE tasks SET status = ? WHERE id = ?',
        ['$status', id]).then((value) {
      getDataFromDatabase(db);
      emit(AppUpdateDatabaseState());
    });
  }

  void deleteData({
    @required int id,
  }) async {
    db.rawDelete('DELETE FROM tasks WHERE id = ?', [id]).then((value) {
      getDataFromDatabase(db);
      emit(AppDeleteDatabaseState());
    });
  }

  bool isButtonSheetShown = false;
  IconData fabIcon = Icons.edit;

  void changeButtomSheet({
    @required bool isShow,
    @required IconData icon,
  }) {
    isButtonSheetShown = isShow;
    fabIcon = icon;
    emit(AppChangeButtomSheet());
  }
}
